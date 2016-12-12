#cloud-config

write_files:
  - path: "/etc/systemd/system/kubelet.service"
    permissions: "0644"
    owner: "root"
    encoding: "base64"
    content: |
      ${kubelet_unit}

coreos:
  units:
    - name: "kubelet.service"
      command: "start"
      enable: true
      drop-ins:
      - name: 10-environment.conf
        content: |
          [Service]
          Environment=KUBE_API_ENDPOINT=http://localhost:8080
