# MetalLBとWindows Hyper-V driverを用いたAgones実行の為のTerraform構成
こちらの構成は[Agones](https://agones.dev/site/docs/)をMetalLBを用いて,Windows Hyper-Vドライバを使用したMinikubeクラスタ上で動作させる事を試みたものです。

[こちらのページに記載されている通り](https://agones.dev/site/docs/installation/creating-cluster/minikube/#local-connection-workarounds) 本来`minikube tunnel`が動作しなかった場合、異なるドライバーを利用する事が推奨されています。  
しかし、個人的な理由で Hyper-Vを利用したかった & Terraformで構成管理をしたかった為
こちらの構成を記載しました。

最終的に[こちらの書き込みを見つけ、](https://github.com/kubernetes/minikube/issues/12362#issuecomment-1034678334)参考にさせて頂きました。

現在のこちらの構成では単に[simple game serverの実行までを構成管理しています。](https://github.com/googleforgames/agones/tree/main/examples/simple-game-server)

# 使用方法
## 通常
1. 「`minikube start --kubernetes-version v1.23.9 -p agones`」を実行してください
    - 手動でドライバーの設定を変更している場合, 「`minikube config set driver hyperv -p agones`」を実行してください。
2. 「`terraform init; terraform apply`」を実行してください。

applyが完了すると、game serverが起動した状態になります。  
[こちらに記載されている通り](https://agones.dev/site/docs/getting-started/create-gameserver/#3-connect-to-the-gameserver) 「`nc`」 や 「`nmap`」を利用する事で確認が可能です。  

1. 上記のツールをインストールします
2. 「`minikube ip -p agones`」を実行し、出力を確認します。 この時出力されているIPアドレスを以下の手順で使用します
3. デフォルトでは`30000`番ポートをゲームサーバに接続できるポートに設定しています, 上記のツールを使用してUDPパケットを送信する事で疎通が確認できます。
    - ncの場合は 「`nc -u (minikube ipで取得したIPアドレス) 30000`」でゲームサーバに接続可能です
    - 接続した状態で`aaa` と送信すると `ACK: aaa`と応答が返却されます

## テストの実行(要:Go環境)
もしお手元でGoの開発環境が構築できる場合、一連の手順を`go test`で確認可能です
- `cd ./test`を実行します
- `go test -v`を実行します
    - 実行時に`agones`という名前のMinikubeのクラスタが存在しない場合、自動でコマンド「`minikube start --kubernetes-version v1.23.9 -p agones`」介して、対象のクラスタが生成されます
    - テストのデフォルト実行では、リソース(Minikubeのクラスタ, MetalLB,AgonesなどのPodやCRD等)は削除されず、維持されます
    - テスト実行後、上記のリソースを削除したい場合は`--clean`フラグを付与して実行する事で対応可能です。例:`go test -v --clean`

# 必要なソフトウェアやツール
[Readme.md](https://github.com/oniku-2929/tf_agones_minikube_hyperv/blob/main/README.md)を参照してください。

# なぜそうしたか、そうしなかったのか
## なぜMetalLBのチャートを分割しているのか？(helm_release.metallb と helm_release.metallb_minikubeについて)
なぜなら,Helmの`pre install` Chart Hookを用いて、生成の際の優先順位をコントロールする事ができなかったからです。
[MetalLBではv0.12以降、各種定義がCRDで定義される形になります。](https://metallb.universe.tf/configuration/migration_to_crds/)
当初は自身が設定するCRD(IPAddressPoolやL2Advertisement)を定義するChartのサブチャートとして、MetalLBの基盤のチャートを含めようとしていました。
しかし、`pre install` hookは[こちらの理由により](https://github.com/helm/helm/issues/11422#issuecomment-1281158642)上手く、動作しませんでした。
その為、Helm単体ではこの依存関係を解決できなかったので、依存関係をTerraform側に移す事にしました。
これがhelm_releaseが2つに分かれている理由です。

# Terraformに関する情報
[Readme.md](https://github.com/oniku-2929/tf_agones_minikube_hyperv/blob/main/README.md)を参照してください。

## Licence
MIT