# Use Azure Firewall to create NAT traffic between 3 VNets

```
              +--------+--------+
              |  ubuntu server  |
              |     global      |
              +-----------------+
                       |
                       |
                       |
              +-----------------+
              |     global      |
              |      VNet       |
              +--------+--------+
                       |
                       |  Vnet peering
                       |
              +--------+--------+
              | Azure Firewall  |
              |      Hub        |
              +--------+--------+
                       |  AzureFirewallSubnet
                       |
              +--------+--------+
              |      hub        |
              |      VNet       |
              +--------+--------+
                       |  Vnet peering + User Defined Route
                       |
              +--------+--------+
              |     spoke1      |
              |      VNet       |
              +--------+--------+
                       |
                       |
              +--------+--------+
              |   myubuntuvm    |
              |    VNet spoke1  |
              +--------+--------+
```

# Deploy and test

```
terraform init
terraform apply
```

To have a shell on the VMs use the serial console:
```
az serial-console connect --name myubuntuvm -g nat-rg
az serial-console connect --name ubuntuserver -g nat-rg
```

To disconnect from the serial console, use the following command:
```
Ctrl + ]
```

Then hit `q` to quit the console.

To test the connection to the VMs, use the following command on the server:
```
python3 -m http.server 8000
```

Then connect from myubuntuvm to ubuntuserver:
```
curl -v 192.168.0.4:8000
```