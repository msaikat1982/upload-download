param virtualMachines_cyberark_dev101_name string = 'cyberark-dev101'
param disks_cyberark_dev101_osdisk_externalid string = '/subscriptions/e657afbe-61e4-4a5f-b6cb-cfbba50fd3a6/resourceGroups/rg-sec-cyberark-dev-01/providers/Microsoft.Compute/disks/cyberark-dev101-osdisk'
param networkInterfaces_cyberark_dev101_nic_externalid string = '/subscriptions/e657afbe-61e4-4a5f-b6cb-cfbba50fd3a6/resourceGroups/rg-sec-cyberark-dev-01/providers/Microsoft.Network/networkInterfaces/cyberark-dev101-nic'

resource virtualMachines_cyberark_dev101_name_resource 'Microsoft.Compute/virtualMachines@2026-03-01' = {
  name: virtualMachines_cyberark_dev101_name
  location: 'centralus'
  tags: {
    Owner: 'security@geha.com'
    Environment: 'dev'
    ApplicationName: 'CyberArk PAS'
    DataClassification: 'Confidential'
    Description: 'Resource supporting dev CyberArk Connectors'
    MigrateProject: 'Datacenter-Transformation'
  }
  identity: {
    type: 'SystemAssigned'
  }
  plan: {
    name: 'cis-windows-server2025-l1-gen2'
    product: 'cis-windows-server'
    publisher: 'center-for-internet-security-inc'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v7'
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    storageProfile: {
      imageReference: {
        publisher: 'center-for-internet-security-inc'
        offer: 'cis-windows-server'
        sku: 'cis-windows-server2025-l1-gen2'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: '${virtualMachines_cyberark_dev101_name}-osdisk'
        createOption: 'FromImage'
        caching: 'None'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
          id: disks_cyberark_dev101_osdisk_externalid
        }
        deleteOption: 'Delete'
        diskSizeGB: 127
      }
      dataDisks: []
      diskControllerType: 'NVMe'
    }
    osProfile: {
      computerName: virtualMachines_cyberark_dev101_name
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: false
        patchSettings: {
          patchMode: 'Manual'
          assessmentMode: 'ImageDefault'
        }
        timeZone: 'Central Standard Time'
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
      adminUsername: 'azureuser'
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces_cyberark_dev101_nic_externalid
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

resource virtualMachines_cyberark_dev101_name_postInstall 'Microsoft.Compute/virtualMachines/runCommands@2026-03-01' = {
  parent: virtualMachines_cyberark_dev101_name_resource
  name: 'postInstall'
  location: 'centralus'
  properties: {
    source: {
      script: 'begin {\n    #Stop an error from occurring when a transcript is already stopped\n    $ErrorActionPreference="SilentlyContinue"\n    Stop-Transcript | out-null\n\n\t$workingFolder = "C:\\Tech-Tools"\n\t\n\t#Create working folder\n\tNew-Item -Path $workingFolder -ItemType Directory -Force | Out-Null\n   \n    $date = get-date -format MM-dd-yyyy\n   \n    #Reset the error level before starting the transcript\n    $ErrorActionPreference="Continue"\n    Start-Transcript -path "$workingFolder\\$($PSCommandPath.Split(\'\\\')[-1].Split(\'.\')[0])-Transcript-$date.log" -append -IncludeInvocationHeader\n}\n\nprocess {\n\n    #\n\t# Check for and install internal CA certificates if they do not exist\n    #\n\t$rootCA  = \'LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUZLakNDQXhLZ0F3SUJBZ0lRTUlmN1p5WGd5S2hMNjhRL3phZDFkREFOQmdrcWhraUc5dzBCQVFzRkFEQVYKTVJNd0VRWURWUVFERXdwSFJVaEJVazlQVkVOQk1CNFhEVEUyTVRFd056RTJORFUwT0ZvWERUTTFNRGd3TVRBeApNakF3TTFvd0ZURVRNQkVHQTFVRUF4TUtSMFZJUVZKUFQxUkRRVENDQWlJd0RRWUpLb1pJaHZjTkFRRUJCUUFECmdnSVBBRENDQWdvQ2dnSUJBUE9PUmdmSWtXMnVlWjJscGdhRm51MW9EQlp3VUIva0ZHMlJLTTlEeW1NaFpCRkwKWEJWSjBYZmxFTkw2VzNJRHlaWXMrT2k3SW9Ib0ZUeGxtV0xnNytjQWZaekRJeHdhR2NjbVlRSzAvbEVReEptdwpRQVBNdDhNMUJDUWRzWDdPUndJd2VhaVVYUWRVNVVJd3RkVXB4UWppd0JZZVBIeWgxVER5L3RLSGRJQ2VIM2lJCmNiK0lEb0RLaHpDRHh6ekM4YkZaVDlXMjloams1Z1pSSENTQ3UySisxOWNWbGREN2N2Yys0dnRzRWU3d2Q1aXoKWGJiZW8vQ2RvM1dNVnRxMlBSSkVhbVp0dERPR2FERmE0UmdaS1pRZlR0clJXdFRhcnVJVzcrRG9UKy84MktCNQpjMitSYU5tMkdKYzZFM1ozS040cjg2MzlteitsUkM1Nk9TSHpscDA1ZDU0Vmp6aHlEMkxUV2VpRWlMMHRNTFdZCm5MVnh1RVRaWXVUVVBHK3ZvS0xLZE0zS0FuR282aGpKVU94a1daa1RvQkY1bnJkWnhOQ2N0MEZGTnNENE9LVmsKcjR2MGlqK1NjWEV1ZEdqM0xoVld4M2FjS013aDFCa28zdlpmSllZbjMvZkxsUlE1eVJ4L3VHNlJkTUNKYW5nZQpCc0l5cDZBSTVpdXZ0R08yc3ZRcFl1NkhRTnVqbnR2SVdrRGdDbFNPK3NLNXpwekVFalRnODA0VUw3cXhMRW9vCjhxOUdnaDAzbS81dE4xV0tSNEdkNysrTmNLUkdOenAzTW9NWGduT0pCdy9LbVpEREJKS0ZrbjBtYkFVdk1GZUcKMW9PdTR3bjR3ZTlRUzl4OGU2RTJzbk1NckRBUGQ2cUMwRDg0K3BIWGZhUitJMXpVZ1NTcmMvK0ZtSWVkQWdNQgpBQUdqZGpCME1Bc0dBMVVkRHdRRUF3SUJoakFQQmdOVkhSTUJBZjhFQlRBREFRSC9NQjBHQTFVZERnUVdCQlFUCitndUJwQUhqd3MvMUh1UEh0Y0JuSmR3YWFEQVFCZ2tyQmdFRUFZSTNGUUVFQXdJQkFUQWpCZ2tyQmdFRUFZSTMKRlFJRUZnUVV5RWwxUVZ4K1FCZFVnZWoyM0J4bHJieVF5UGN3RFFZSktvWklodmNOQVFFTEJRQURnZ0lCQUN6MQpDZi8wYXVMRFdROUUvcncrWEhvSExtMkJTSHFCTnlVTGdrMVRNd2xvZnRCMlZ2N1ZiRW5TN3lUaUJUVGdMVzVGCmV4T01yakg5bVFnTnRVWnRVeUJabENPQy9MV2ZUMUtLVitTeDdxVFhDdUlxd09YV1FuQ0lqVTcvN2wxM3N0VDkKUlpYU1luTm5nMXhXbGZXemxpbnN4dTBXaXY1WG00ZTR2OHpkMitMUVB4dy9kWmpBV1BOMEZ6a2Z6Q2I4alRRZgp0czRQSElvRm9GTHJHdExCbTNXcXk1V3FoN1ZBUDBka0QveHNwR0FrYTRFYnZ6VTdKYlFPT1hwcEkza2EyS2s1CkxHNHgxdmwwMFZBM0J4MGQ1QWlqTENMcWZBSURCQWp2OWZvK0cxekFzTDYwaUVTc09mbHUwYWNlWndCaGJ5Wm8KTDN5dzR5OXVmMzVLOGcza25IWTlrR2RqQlkrbUI2UzhVN2c2cXN2TktjUWpGbW1xS0xuOGlZWG1DSHFjVkhRbwpVRHBVK01Kak8wRWJJbkh2THZ2YUVHWkMrRmZwZFFqUjdIREc2dE1rbGNVQmRjUWV0YTdSRXpJYXlDaW9OTlRaClEyUUVUdFJxY2RTZzlFcFhackNRT3d2eXlMem9rbngrQ1ljaEtEMjJLV2o3aGhLeS8wVkFMY2twM1gyVlM2dDEKZnlkbGVkVll2Q0ZWdGxqRzVNc3JDU3MwdEo5SDE4SjZCQWdkcnFIZTFVS1pIM3FrT2xNVms5TG5FNlArdm1zcgpKd1Q3VERTck9qWUQyenZuaHZCN05IcjErN01XOXdoanF5SlVvdCtzdFJGNGhPenh1SWdxT1VUL0t5Ti9ZQ3p5Ci9SRmFYaDBka3JOa3BoUkRSRW4ydnh4SllaaTZaWSszSjRHUVhDOU4KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQ==\'\n\t$intCA = \'LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUdNVENDQkJtZ0F3SUJBZ0lUY1FBQUFBV1E2S1F3Z0lXYzlBQUJBQUFBQlRBTkJna3Foa2lHOXcwQkFRc0YKQURBVk1STXdFUVlEVlFRREV3cEhSVWhCVWs5UFZFTkJNQjRYRFRJMU1EZ3dNVEF4TkRNeE0xb1hEVE0wTURndwpNVEF4TlRNeE0xb3dSekVUTUJFR0NnbVNKb21UOGl4a0FSa1dBMk52YlRFVU1CSUdDZ21TSm9tVDhpeGtBUmtXCkJFZEZTRUV4R2pBWUJnTlZCQU1URVVkRlNFRlRTRUV5U1hOemRXbHVaME5CTUlJQ0lqQU5CZ2txaGtpRzl3MEIKQVFFRkFBT0NBZzhBTUlJQ0NnS0NBZ0VBcjcvSVJ6WU5vejNKandMbnBqejh4MDNVNUNnTy9YcDZIKzVXdE0vTwpkc1JCWWh1QTlkdU4zSnRGZE1qbURRbHNhYTcwMDFOSkhrRnNmczkxaXBHa3c3eVgyQWhVREU1RUYzTzArSWZkCnRIdXo4UWsrYVNSTGg0YnMzOEtuNEdzdzdPNWtVNHJ1Sy83NWwxS1hON3lYc0hJZFpoNHVTdDhjVlVSUEdPZDEKVHd4UzF2cXFxMGVHQk1seGFTd1hvRUZhbUtNaGVKZEpQYXZuVEExWHZkQ0ZuQjBHaHZUcW1TUW1hRXY4VVo2QQpKcHl3QlVQNWUvVGgzRkhxc0RwUG5ZTW9CYlozOGM2Ym5zcEJwM0c3ME9MQ1RralhyeHhEKzBwNURzalJJVEFhClVtRDhKTThmWEdsS1NCaGpHdEVQN0xXVWxqdzhxZ1MxWEptOVI0SGQzdEc1NTkyNVU2aENCUXR2WG4xeDR3VFYKN2Nmd3YrN25vRDBoNnBMS1NXWktvdGp2Ry9IOTI3RzIvN2JIaTl3TE4xUlA1T3U2Q0hqU00xTlNmRHRRa1Z6UgpZVk44eTJrWHNSaHJMZU9oR2JBSDd5bFZnV2o2N0dtc3Z3WXpTS1dOZytIcWtaVnlFMHhoaXh0ZkFLWGtWZnhwCmVSbWtVd09iWEUrSnRzakk2WTVrYnRyaktBMExvS0h0NFpzdnBJQjg4K1ZzbjRiMUJ2cFR0ZEd4M08rTXpKV0QKbE1zL2JFMlYvL2Y3OU9pNS9zK2NqSm10ZHMyenIyemwzSU9VdlJMNFhuRnMrRXBHQlkvTExCalhaMkRkckozdQovRXNSK2l5cHJKRkJGT2hxemNvSitmOTR3UkEvTmRUZkorNHVQNW5pSXB2TzNIS2FkT25heWhwVk82YkZ0ZWR4Cnhma0NBd0VBQWFPQ0FVWXdnZ0ZDTUJJR0NTc0dBUVFCZ2pjVkFRUUZBZ01CQUFJd0l3WUpLd1lCQkFHQ054VUMKQkJZRUZGVXRmbnFhU1NrMEluOFJpUzIwNm51amFzY3hNQjBHQTFVZERnUVdCQlJpY0RkSGg0SXJNb1dQUFRwWAp6VWpnWnJLeFJUQVpCZ2tyQmdFRUFZSTNGQUlFREI0S0FGTUFkUUJpQUVNQVFUQUxCZ05WSFE4RUJBTUNBWVl3CkR3WURWUjBUQVFIL0JBVXdBd0VCL3pBZkJnTlZIU01FR0RBV2dCUVQrZ3VCcEFIandzLzFIdVBIdGNCbkpkd2EKYURBN0JnTlZIUjhFTkRBeU1EQ2dMcUFzaGlwb2RIUndPaTh2Wlc1MFkyRXdOQzVuWldoaExtTnZiUzlqWkhBdgpSMFZJUVZKUFQxUkRRUzVqY213d1VRWUlLd1lCQlFVSEFRRUVSVEJETUVFR0NDc0dBUVVGQnpBQ2hqVm9kSFJ3Ck9pOHZaVzUwWTJFd05DNW5aV2hoTG1OdmJTOWpaSEF2UlU1VVEwRXdNMTlIUlVoQlVrOVBWRU5CS0RFcExtTnkKZERBTkJna3Foa2lHOXcwQkFRc0ZBQU9DQWdFQUtoUmpqRE56S1Bkc0dVZmVSaXlUaWp5dHUzd0JIblpyWFI3VQpRclh1OHdyOHpEczF0WlBCQjhublZVQnh1UVdGeHB1QWtYczNBR2dBVFc4U1B4RTIzZy9uSFAwSlYvcGM0SFF2CnRYTGdXbGR0SGs5OThCemtUK0NRa2svYVpWakRNWjBlN1h3WE5FL1F0NTk4ekluRlJhUWZvUktFS2pLT09nREEKQlZqcEhMOVpwUnUrblRoQVdlWXkzaEhIUEx1QWxrZUJNc0xvU1NVTEwrTlpma2JwbTFwZVNKMDY2NmhRUVNTeApLcUxiazRnMzlXQ0EwMFdjYmFSZGdQVlhSU0VIUDV4UDhJc2hlaytLVm1nUk9lUVhVVm9NSUNkZzRXVitQbyt4CkN3U0VsNlBiZEVVQWxQOXg5S2c4WjRYL1ZQZ29Bb1VlM1pZb05NcVBBREM2WDNhM3FvT2RvdUJCb3dHUGhNRTUKNE42NVF4M29qaTFnZXNNTm9uZkJUcDVjaFg2U0VoYkpXc2RqdDdVbGhISy84OHdOTklLMHREQjN0eStKR1FBawovcFZUWGlaOTN4KzVKanZYTEVVdWYyd0l3bnI4cEtsZE5HM2lEL3dxVnNlbXY0N2svZDBQbGxpT3RDaUNXQlE3CkpEODV0R0V5SUVnRytBMEhRMnJOdWFhSjJTcGNzNERwcXZlN0NxREl1VHhSSmNxMG9sd2xHWklKVXFkd2pPWTkKSXFUaWVkY0RmUDRGb3BqTmlmbm1OYWl1RHZaSWJhS1FFbjVndHNLbzdvdDhWT3l6ZEVwQzBnTkhITEVTaTE3SApiWmFBcmJnSkxZVjEwamE4YlFFcndWdGZGZFVIV2NjQk43SUVEZEhpdElhbEJrQkpWbXI4LzZSb2k1YTBWUGxyClpNMk1yNGc9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0=\'\n\n\tif (!(Get-ChildItem -Path "Cert:\\CurrentUser\\Root" | Where-Object {$_.Thumbprint -match "ce3a2a708b68529e587fb01b854063a783ca2687"})) {\n\t\t$tempPathRoot = "$workingFolder\\tempCertRoot.cer"\n\t\t$certBytesRoot = [System.Convert]::FromBase64String($rootCA)\n\t\t[System.IO.File]::WriteAllBytes($tempPathRoot, $certBytesRoot)\n\t\tImport-Certificate -FilePath $tempPathRoot -CertStoreLocation Cert:\\LocalMachine\\Root\n\t\tRemove-Item $tempPathRoot\n\t}\n\n\tif (!(Get-ChildItem -Path "Cert:\\CurrentUser\\CA" | Where-Object {$_.Thumbprint -match "365cd08a8e34bbeff257f658d94f883eb5470f05"})) {\n\t\t$tempPathInt = "$workingFolder\\tempCertInt.cer"\n\t\t$certBytesInt = [System.Convert]::FromBase64String($intCA)\n\t\t[System.IO.File]::WriteAllBytes($tempPathInt, $certBytesInt)\n\t\tImport-Certificate -FilePath $tempPathInt -CertStoreLocation Cert:\\LocalMachine\\CA\n\t\tRemove-Item $tempPathInt\n\t}\n\t\n    \n    #\n\t# Resize C:\\ partition to use all free space\n    #\n\tResize-Partition -DriveLetter C -Size ((Get-PartitionSupportedSize -DriveLetter C).SizeMax) -Verbose\n}\n\nend{\n    #Stop Transcript\n    Stop-Transcript | out-null\n}\n'
    }
    timeoutInSeconds: 0
    asyncExecution: false
    treatFailureAsDeploymentFailure: true
  }
}
