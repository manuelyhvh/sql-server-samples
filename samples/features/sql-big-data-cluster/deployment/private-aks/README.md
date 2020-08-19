# Deploy BDC in private AKS cluster with User-defined Route (UDR)

This repository contains the scripts that you can use to deploy a BDC cluster in Azure Kubernetes Service (AKS) private cluster with advanced networking ( CNI ). 

This repository contains 3 bash scripts : 
- **deploy-private-aks.sh** : You can use it to deploy private AKS cluster with private endpoint, it fits the use case that you need to deploy BDC with a private endpoint with AKS private cluster.
- **deploy-private-aks-udr.sh** : You can use it to deploy private AKS cluster with private endpoint, it fits the use case that you need to deploy BDC with a private endpoint with AKS private cluster and limit egress traffic with UDR ( User-defined Routes ). 
- **deploy-bdc.sh** : You can use it to deploy Big Data Clusters ( BDC ) in private deployment mode on private AKS cluster with or without User-defined routes based on your project requirements. 


## Prerequisites

You can run those scripts on the following client envionrment with Linux OS or WSL/WSL2.

The following table lists common big data cluster tools and how to install them:

| Tool | Required | Description | Installation |
|---|---|---|---|
| `python` | Yes | Python is an interpreted, object-oriented, high-level programming language with dynamic semantics. Many parts of big data clusters for SQL Server use python. | [Install python](#python)|
| `azdata` | Yes | Command-line tool for installing and managing a big data cluster. | [Install](deploy-install-azdata.md) |
| `kubectl`<sup>1</sup> | Yes | Command-line tool for monitoring the underlying Kubernetes cluster ([More info](https://kubernetes.io/docs/tasks/tools/install-kubectl/)). | [Windows](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-with-powershell-from-psgallery) \| [Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-using-native-package-management) |
| **Azure Data Studio** | Yes | Cross-platform graphical tool for querying SQL Server. | [Install](https://aka.ms/getazuredatastudio) |
| **Data Virtualization extension** | Yes | Extension for Azure Data Studio that provides a Data Virtualization wizard. | [Install](../azure-data-studio/data-virtualization-extension.md) |
| **Azure CLI**<sup>2</sup> | For AKS | Modern command-line interface for managing Azure services. Used with AKS big data cluster deployments ([More info](https://docs.microsoft.com/cli/azure/?view=azure-cli-latest)). | [Install](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest) |
| **mssql-cli** | Optional | Modern command-line interface for querying SQL Server ([More info](../tools/mssql-cli.md)). | [Windows](https://github.com/dbcli/mssql-cli/blob/master/doc/installation/windows.md) \| [Linux](https://github.com/dbcli/mssql-cli/blob/master/doc/installation/linux.md) |
| **sqlcmd** | For some scripts | Legacy command-line tool for querying SQL Server ([More info](https://docs.microsoft.com/sql/tools/sqlcmd-utility?view=sql-server-ver15)). You might need to install the Microsoft ODBC Driver 11 for SQL Server before installing the SQLCMD package. | [Windows](https://www.microsoft.com/download/details.aspx?id=36433) \| [Linux](../linux/sql-server-linux-setup-tools.md) |
| `curl` <sup>3</sup> | For some scripts | Command-line tool for transferring data with URLs. | [Windows](https://curl.haxx.se/windows/) \| Linux: install curl package |
| `oc` | Required for Red Hat OpenShift and Azure Redhat OpenShift deployments. |`oc` is the Open Shift command line interface (CLI). | [Installing the CLI](https://docs.openshift.com/container-platform/4.4/cli_reference/openshift_cli/getting-started-cli.html#installing-the-cli)



## Instructions

### deploy-private-aks.sh

1. Download the script on the location that you are planning to use for the deployment

``` bash
curl --output setup-bdc.sh https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/features/sql-big-data-cluster/deployment/private-aks/scripts/deploy-private-aks.sh
```

2. Make the script executable

``` bash
chmod +x deploy-private-aks.sh
```

3. Run the script (make sure you are running with sudo)

``` bash
sudo ./deploy-private-aks.sh
```

### deploy-private-aks-udr.sh

1. Download the script on the location that you are planning to use for the deployment

``` bash
curl --output setup-bdc.sh https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/features/sql-big-data-cluster/deployment/private-aks/scripts/deploy-private-aks-udr.sh
```

2. Make the script executable

``` bash
chmod +x deploy-private-aks-udr.sh
```

3. Run the script (make sure you are running with sudo)

``` bash
sudo ./deploy-private-aks-udr.sh
```

### deploy-bdc.sh

1. Download the script on the location that you are planning to use for the deployment

``` bash
curl --output setup-bdc.sh https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/features/sql-big-data-cluster/deployment/private-aks/scripts/deploy-bdc.sh
```

2. Make the script executable

``` bash
chmod +x deploy-bdc.sh
```

3. Run the script (make sure you are running with sudo)

``` bash
sudo ./deploy-bdc.sh
```

