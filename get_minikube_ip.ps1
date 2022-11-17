$minikubeIP = minikube ip -p agones
Write-Output "{ ""address"" : ""$minikubeIP""}"
