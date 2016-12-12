[Unit]
Description=Kubernetes kubelet agent
After=docker.service
Requires=docker.service

[Service]
Restart=always
Environment=KUBELET_VERSION=${kube_version}
ExecStart=/usr/lib/coreos/kubelet-wrapper \
  --api-servers=$$KUBE_API_ENDPOINT \
  --config=/etc/kubernetes/manifests \
  --allow-privileged=true \
  --cloud-provider=aws

[Install]
WantedBy=multi-user.target