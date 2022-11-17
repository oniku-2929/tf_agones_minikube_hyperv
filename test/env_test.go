package test

import (
	"bufio"
	"flag"
	"fmt"
	"net"
	"os"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

const (
	workDir             = "../"
	TIMEOUT_SECONDS     = 20
	RECV_BUFF_SIZE      = 1500
	RETRY_COUNT         = 5
	RETRY_SLEEP_SECONDS = 1
)

var clean = flag.Bool("clean", false, "Clean resources (Terraform, Minikube cluster) after the test.")
var refresh = flag.Bool("refresh", false, "Refresh Minikube cluster environment before running the test.")

func TestMain(t *testing.M) {
	usage := `Basic usages:
Normal Test: "go test -v" => reuse&retain resources.
Clean Test: "go test -v --clean" => clean resources after the test.
Refresh Test: "go test -v --refresh" => refresh resources(destory and create).
Refresh&Clean Test: "go test -v --refresh --clean " => refresh resources and clean resources after the test.
`
	flag.Usage = func() {
		fmt.Fprintf(os.Stdout, "%s\n", usage)
		flag.PrintDefaults()
	}
	flag.Parse()
	os.Exit(t.Run())
}

func TestAgonesWithMetalLB(t *testing.T) {
	cmdStart := shell.Command{
		Command:    "minikube",
		Args:       []string{"start", "--kubernetes-version", "v1.23.9", "-p", "agones"},
		WorkingDir: workDir,
	}
	cmdDel := shell.Command{
		Command:    "minikube",
		Args:       []string{"delete", "-p", "agones"},
		WorkingDir: workDir,
	}
	if *refresh {
		err := shell.RunCommandE(t, cmdDel)
		assert.NoError(t, err, fmt.Sprintf("Assertion failed, shell.RunCommandE command:%v", cmdDel))
		err = shell.RunCommandE(t, cmdStart)
		assert.NoError(t, err, fmt.Sprintf("Assertion failed, shell.RunCommandE command:%v", cmdStart))
	} else {
		cmdCheck := shell.Command{
			Command:    "minikube",
			Args:       []string{"status", "-p", "agones"},
			WorkingDir: workDir,
		}
		err := shell.RunCommandE(t, cmdCheck)
		if err != nil {
			err = shell.RunCommandE(t, cmdStart)
			assert.NoError(t, err, fmt.Sprintf("Assertion failed, shell.RunCommandE command:%v", cmdStart))
		}
	}

	if *clean {
		defer shell.RunCommand(t, cmdDel)
	}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: workDir,
	})

	terraform.InitAndApply(t, terraformOptions)
	if *clean {
		defer terraform.Destroy(t, terraformOptions)
	}

	//All of LoadBalancer Service IP are same as "minikube ip".
	cmdIP := shell.Command{
		Command:    "minikube",
		Args:       []string{"ip", "-p", "agones"},
		WorkingDir: workDir,
	}
	minikubeIP, err := shell.RunCommandAndGetStdOutE(t, cmdIP)
	assert.NoError(t, err, "Assertion failed, RunCommandAndGetStdOutE")

	optK8s := k8s.NewKubectlOptions("agones", "", "default")
	outSVC, err := k8s.RunKubectlAndGetOutputE(t, optK8s, "get", "svc", "-o=jsonpath='{.items[*].spec.loadBalancerIP}'", "--all-namespaces")
	assert.NoError(t, err, "Assertion failed, RunKubectlAndGetOutputE")

	arrLBIP := strings.Split(strings.Trim(outSVC, "'"), " ")
	for _, elem := range arrLBIP {
		assert.Equal(t, minikubeIP, elem)
	}

	//Can it Send UDP message to game server?
	gameServerPortStr, err := terraform.OutputE(t, terraformOptions, "port_gameserver")
	assert.NoError(t, err, "Assertion failed, terraform.OutputE")
	gameServerPort, err := strconv.Atoi(gameServerPortStr)
	assert.NoError(t, err, "Assertion failed, strconv.Atoi")

	endPoint := fmt.Sprintf("%s:%d", minikubeIP, gameServerPort)

	description := "Send UDP packet to gameserver."
	_, err = retry.DoWithRetryE(t, description, RETRY_COUNT, time.Second*RETRY_SLEEP_SECONDS, func() (string, error) {
		conn, err := net.Dial("udp4", endPoint)
		if err != nil {
			return "Error net.Dial", err
		}

		err = conn.SetDeadline(time.Now().Add(time.Second * TIMEOUT_SECONDS))
		if err != nil {
			return "Error conn.SetDeadline", err
		}

		defer conn.Close()

		msg := "aaa"
		_, err = conn.Write([]byte(msg))
		if err != nil {
			return "Error conn.Write", err
		}

		recvBuf := make([]byte, RECV_BUFF_SIZE)
		length, err := bufio.NewReader(conn).Read(recvBuf)
		if err != nil {
			return "Error bufio.NewReader(conn).Read", err
		}

		recvMsg := string(recvBuf[:length])
		assert.Equal(t, fmt.Sprintf("ACK: %s\n", msg), recvMsg)

		return "Successd", nil
	})
	assert.NoError(t, err, "Assertion failed, conn.SetDeadline")
}
