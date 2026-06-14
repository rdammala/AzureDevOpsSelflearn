# Python for DevOps & Infrastructure Automation - Step-by-Step Guide

> ⏱️ **Study Time:** 45-60 minutes | **Level:** Beginner to Intermediate

## Overview

Python is one of the most popular languages for DevOps automation due to its simplicity, extensive libraries, and cross-platform support.

**What You'll Learn:**
- Python basics (variables, loops, functions)
- Working with Azure SDK
- Building deployment scripts
- Cloud automation patterns
- Error handling and logging

---

## Step 1: Python Basics

### Installation & Setup

```bash
# Check Python version
python --version

# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Activate (Linux/Mac)
source venv/bin/activate

# Install packages
pip install azure-identity azure-mgmt-resource requests
```

### Variables & Data Types

```python
# Variables (no type declaration needed)
service_name = "Chat"
port = 8080
is_production = True
deployment_time = None

# Collections
services = ["Chat", "Search", "Refunds", "Notifications"]
config = {
    "environment": "prod",
    "region": "eastus",
    "vm_size": "Standard_D2s_v3"
}
replicas = (1, 2, 3, 4, 5)  # Tuple (immutable)

# String operations
print(f"Deploying {service_name} on port {port}")
print(f"Services: {', '.join(services)}")

# Type checking
print(type(service_name))  # <class 'str'>
print(isinstance(port, int))  # True
```

---

## Step 2: Control Flow & Loops

### If/Else Statements

```python
environment = "prod"

if environment == "prod":
    timeout = 300
    max_retries = 5
elif environment == "staging":
    timeout = 180
    max_retries = 3
else:
    timeout = 60
    max_retries = 1

# Conditional expression
message = "Production" if is_production else "Development"

# Multiple conditions
if is_production and has_backup:
    print("Safe to deploy")
```

### Loops

```python
# For loop with range
for i in range(1, 6):
    print(f"Attempt {i}")

# For loop over list
services = ["Chat", "Search", "Refunds"]
for service in services:
    print(f"Deploying {service}...")

# For loop with enumerate (get index and value)
for idx, service in enumerate(services):
    print(f"{idx + 1}. {service}")

# For loop with zip (iterate over multiple lists)
names = ["Chat", "Search", "Refunds"]
versions = ["1.0", "2.1", "1.5"]
for name, version in zip(names, versions):
    print(f"{name} v{version}")

# While loop
retries = 0
while retries < 3:
    try:
        # Attempt deployment
        break
    except Exception as e:
        retries += 1
        print(f"Retry {retries}...")
```

### List Comprehension (Pythonic!)

```python
# Create list of numbers squared
squares = [x**2 for x in range(1, 6)]  # [1, 4, 9, 16, 25]

# Filter list
prod_services = [s for s in services if s.startswith("P")]

# Dictionary comprehension
config_items = {k: v.upper() for k, v in config.items()}
```

---

## Step 3: Functions & Modules

### Creating Reusable Functions

```python
# Simple function
def greet(name):
    return f"Hello, {name}!"

print(greet("DevOps"))

# Function with default parameters
def deploy_service(service_name, environment="dev", replicas=1):
    print(f"Deploying {service_name} to {environment} with {replicas} replicas")
    return {"status": "deployed", "service": service_name}

result = deploy_service("Chat", environment="prod", replicas=3)

# Variable arguments
def deploy_multiple(*services, environment="dev"):
    for service in services:
        print(f"Deploying {service} to {environment}")

deploy_multiple("Chat", "Search", "Refunds", environment="prod")

# Keyword arguments
def create_resource(**kwargs):
    for key, value in kwargs.items():
        print(f"{key}: {value}")

create_resource(name="storage", location="eastus", tier="premium")

# Docstrings
def validate_environment(env):
    """
    Validate that environment is one of prod, staging, or dev.
    
    Args:
        env (str): Environment name
        
    Returns:
        bool: True if valid
        
    Raises:
        ValueError: If environment is invalid
    """
    valid = ["prod", "staging", "dev"]
    if env not in valid:
        raise ValueError(f"Invalid environment: {env}")
    return True
```

---

## Step 4: Error Handling

### Robust Error Handling

```python
import logging
from typing import Optional

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Try-except-finally
def deploy_with_error_handling():
    try:
        # Risky operation
        result = deploy_service("Chat", "prod")
        logger.info(f"Deployment successful: {result}")
    except ValueError as e:
        logger.error(f"Validation error: {e}")
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
    finally:
        logger.info("Cleanup operations here")

# Custom exception
class DeploymentError(Exception):
    """Custom exception for deployment failures"""
    pass

def deploy_with_custom_error():
    try:
        validate_environment("invalid")
    except ValueError:
        raise DeploymentError("Deployment failed: invalid environment")

# Retry logic with exponential backoff
import time
from typing import Callable

def retry_with_backoff(func: Callable, max_retries=3, backoff_factor=2):
    for attempt in range(1, max_retries + 1):
        try:
            return func()
        except Exception as e:
            if attempt == max_retries:
                raise
            
            delay = backoff_factor ** (attempt - 1)
            logger.warning(f"Attempt {attempt} failed, retrying in {delay}s: {e}")
            time.sleep(delay)

# Usage
def risky_operation():
    # Simulate unreliable operation
    import random
    if random.random() < 0.7:
        raise ConnectionError("Service unavailable")
    return "Success"

try:
    result = retry_with_backoff(risky_operation, max_retries=3)
    print(f"Result: {result}")
except Exception as e:
    print(f"Failed after retries: {e}")
```

---

## Step 5: Working with Azure SDK

### Authenticating & Managing Resources

```python
from azure.identity import DefaultAzureCredential, ClientSecretCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.resource.models import ResourceGroup
import os

# Authentication (multiple methods)
# Method 1: DefaultAzureCredential (auto-detects environment)
credential = DefaultAzureCredential()

# Method 2: Client Secret (for service principals)
# credential = ClientSecretCredential(
#     tenant_id=os.getenv("AZURE_TENANT_ID"),
#     client_id=os.getenv("AZURE_CLIENT_ID"),
#     client_secret=os.getenv("AZURE_CLIENT_SECRET")
# )

subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")
resource_client = ResourceManagementClient(credential, subscription_id)

# Create resource group
def create_resource_group(name: str, location: str) -> ResourceGroup:
    logger.info(f"Creating resource group: {name}")
    
    rg_body = ResourceGroup(location=location, tags={"env": "dev"})
    rg = resource_client.resource_groups.create_or_update(name, rg_body)
    
    logger.info(f"✓ Resource group created: {rg.name}")
    return rg

# List resource groups
def list_resource_groups() -> list:
    logger.info("Listing resource groups")
    rgs = resource_client.resource_groups.list()
    
    for rg in rgs:
        print(f"- {rg.name} ({rg.location})")
    
    return list(rgs)

# Delete resource group
def delete_resource_group(name: str):
    logger.info(f"Deleting resource group: {name}")
    resource_client.resource_groups.begin_delete(name).wait()
    logger.info(f"✓ Resource group deleted")

# Usage
try:
    create_resource_group("rg-demo-prod", "eastus")
except Exception as e:
    logger.error(f"Failed to create resource group: {e}")
```

---

## Step 6: HTTP Requests & API Calls

### Working with REST APIs

```python
import requests
import json
from typing import Dict, Any

class ApiClient:
    def __init__(self, base_url: str, timeout: int = 10):
        self.base_url = base_url
        self.timeout = timeout
        self.session = requests.Session()
    
    def get(self, endpoint: str) -> Dict[str, Any]:
        url = f"{self.base_url}/{endpoint}"
        logger.info(f"GET {url}")
        
        try:
            response = self.session.get(url, timeout=self.timeout)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"Request failed: {e}")
            raise
    
    def post(self, endpoint: str, data: Dict[str, Any]) -> Dict[str, Any]:
        url = f"{self.base_url}/{endpoint}"
        logger.info(f"POST {url}")
        
        try:
            response = self.session.post(
                url,
                json=data,
                timeout=self.timeout,
                headers={"Content-Type": "application/json"}
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"Request failed: {e}")
            raise
    
    def health_check(self, service_url: str) -> bool:
        """Check if service is healthy"""
        try:
            response = self.session.get(
                f"{service_url}/health",
                timeout=5
            )
            return response.status_code == 200
        except:
            return False

# Usage
api_client = ApiClient("https://api.example.com")

try:
    # Get service status
    status = api_client.get("services/chat")
    print(f"Status: {status}")
    
    # Deploy new version
    deploy_data = {
        "service": "chat",
        "version": "2.1.0",
        "replicas": 3
    }
    result = api_client.post("deploy", deploy_data)
    print(f"Deployment result: {result}")
    
except Exception as e:
    logger.error(f"API call failed: {e}")
```

---

## Step 7: Building Deployment Scripts

### Complete Deployment Example

```python
#!/usr/bin/env python3
"""
Complete deployment utility for Azure services
"""

import argparse
import os
import sys
import logging
from datetime import datetime
from typing import List, Dict
from dataclasses import dataclass

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(f"deployment_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log")
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class DeploymentConfig:
    """Deployment configuration"""
    environment: str
    version: str
    services: List[str]
    subscription_id: str
    location: str = "eastus"
    max_retries: int = 3

class DeploymentTool:
    def __init__(self, config: DeploymentConfig):
        self.config = config
        logger.info(f"Initialized deployment tool for {config.environment}")
    
    def validate(self) -> bool:
        """Validate deployment configuration"""
        logger.info("Validating configuration...")
        
        valid_environments = ["dev", "staging", "prod"]
        if self.config.environment not in valid_environments:
            logger.error(f"Invalid environment: {self.config.environment}")
            return False
        
        if not self.config.services:
            logger.error("No services specified for deployment")
            return False
        
        logger.info("✓ Configuration validation passed")
        return True
    
    def deploy(self) -> bool:
        """Execute deployment"""
        try:
            if not self.validate():
                return False
            
            logger.info(f"Starting deployment of {len(self.config.services)} services")
            
            for service in self.config.services:
                if not self.deploy_service(service):
                    return False
            
            logger.info("✓ All services deployed successfully")
            return True
            
        except Exception as e:
            logger.error(f"Deployment failed: {e}", exc_info=True)
            return False
    
    def deploy_service(self, service: str) -> bool:
        """Deploy individual service"""
        logger.info(f"Deploying {service} v{self.config.version}...")
        
        try:
            # Simulate deployment (replace with actual logic)
            import time
            time.sleep(1)
            
            logger.info(f"✓ {service} deployed to {self.config.environment}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to deploy {service}: {e}")
            return False

def main():
    parser = argparse.ArgumentParser(
        description="Deploy Azure services"
    )
    parser.add_argument(
        "--environment",
        required=True,
        choices=["dev", "staging", "prod"],
        help="Target environment"
    )
    parser.add_argument(
        "--version",
        required=True,
        help="Version to deploy"
    )
    parser.add_argument(
        "--services",
        required=True,
        nargs="+",
        help="Services to deploy"
    )
    parser.add_argument(
        "--subscription",
        default=os.getenv("AZURE_SUBSCRIPTION_ID"),
        help="Azure subscription ID"
    )
    
    args = parser.parse_args()
    
    if not args.subscription:
        logger.error("Azure subscription ID not provided")
        sys.exit(1)
    
    config = DeploymentConfig(
        environment=args.environment,
        version=args.version,
        services=args.services,
        subscription_id=args.subscription
    )
    
    tool = DeploymentTool(config)
    success = tool.deploy()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
```

**Usage:**
```bash
./deploy.py --environment prod --version 2.1.0 --services Chat Search Refunds
```

---

## Step 8: Configuration Management

### Working with Environment Variables & Config Files

```python
import os
import json
from pathlib import Path
from typing import Dict, Any

class Config:
    """Configuration management"""
    
    def __init__(self, env: str = "dev"):
        self.env = env
        self.config = self._load_config()
    
    def _load_config(self) -> Dict[str, Any]:
        """Load configuration from environment variables and config files"""
        config = {
            "environment": self.env,
            "subscription_id": os.getenv("AZURE_SUBSCRIPTION_ID"),
            "tenant_id": os.getenv("AZURE_TENANT_ID"),
            "client_id": os.getenv("AZURE_CLIENT_ID"),
            "client_secret": os.getenv("AZURE_CLIENT_SECRET"),
        }
        
        # Load from JSON config file
        config_file = f"config_{self.env}.json"
        if Path(config_file).exists():
            with open(config_file) as f:
                file_config = json.load(f)
                config.update(file_config)
        
        return config
    
    def get(self, key: str, default: Any = None) -> Any:
        """Get configuration value"""
        return self.config.get(key, default)
    
    def __getitem__(self, key: str) -> Any:
        return self.config[key]

# config_prod.json
"""
{
  "resource_group": "rg-prod-apps",
  "vm_size": "Standard_D4s_v3",
  "replicas": 3,
  "timeout": 300
}
"""

# Usage
config = Config(env="prod")
print(config["resource_group"])
print(config.get("timeout", 60))
```

---

## Step 9: Testing & Validation

### Unit Testing with pytest

```python
import pytest
from unittest.mock import Mock, patch

class TestDeploymentTool:
    
    def test_validate_valid_environment(self):
        config = DeploymentConfig(
            environment="prod",
            version="1.0.0",
            services=["Chat"],
            subscription_id="sub-123"
        )
        tool = DeploymentTool(config)
        
        assert tool.validate() == True
    
    def test_validate_invalid_environment(self):
        config = DeploymentConfig(
            environment="invalid",
            version="1.0.0",
            services=["Chat"],
            subscription_id="sub-123"
        )
        tool = DeploymentTool(config)
        
        assert tool.validate() == False
    
    @patch('requests.Session.get')
    def test_health_check_success(self, mock_get):
        mock_response = Mock()
        mock_response.status_code = 200
        mock_get.return_value = mock_response
        
        client = ApiClient("https://api.example.com")
        assert client.health_check("https://service.com") == True

# Run tests
# pytest test_deployment.py -v
```

---

## Step 10: Advanced - Building CLI Tools

### Creating Professional CLI Applications

```python
import click
from tabulate import tabulate

@click.group()
def cli():
    """Azure deployment utility"""
    pass

@cli.command()
@click.option("--name", required=True, help="Resource group name")
@click.option("--location", default="eastus", help="Location")
def create_rg(name: str, location: str):
    """Create a resource group"""
    click.echo(f"Creating resource group {name}...")
    try:
        # Create logic here
        click.secho(f"✓ Created: {name}", fg="green")
    except Exception as e:
        click.secho(f"✗ Error: {e}", fg="red")

@cli.command()
def list_rgs():
    """List resource groups"""
    click.echo("Listing resource groups...")
    
    data = [
        ["rg-prod", "eastus", "2024-01-15"],
        ["rg-staging", "eastus", "2024-01-10"],
        ["rg-dev", "westus", "2024-01-20"],
    ]
    
    click.echo(tabulate(data, headers=["Name", "Location", "Created"]))

if __name__ == "__main__":
    cli()
```

**Usage:**
```bash
python cli.py create-rg --name rg-prod --location eastus
python cli.py list-rgs
```

---

## Key Python Packages for DevOps

| Package | Purpose |
|---------|---------|
| `azure-identity` | Azure authentication |
| `azure-mgmt-*` | Azure service management |
| `requests` | HTTP client |
| `click` | CLI building |
| `pyyaml` | YAML parsing |
| `jinja2` | Template rendering |
| `pytest` | Unit testing |
| `paramiko` | SSH connections |
| `boto3` | AWS SDK |

---

## Troubleshooting Tips

| Problem | Solution |
|---------|----------|
| Module not found | `pip install --upgrade pip` then `pip install module-name` |
| Virtual env issues | Delete venv folder and recreate |
| Azure auth failing | Check `az login` status, verify environment variables |
| Script not executable | `chmod +x script.py` (Linux/Mac) |
| Timeout errors | Increase timeout value in requests |

---

## Practice Exercises

1. **Build a resource auditor** that lists all resources and their creation dates
2. **Create a cost calculator** that estimates monthly costs based on resources
3. **Write a backup utility** that backs up resource configurations to JSON
4. **Build a health monitor** that checks service endpoints periodically

---

## Next Steps

- 🎯 Explore advanced Azure SDK patterns
- 🎯 Build production-grade CLI tools
- 🎯 Integrate with CI/CD pipelines
- 🎯 Create reusable modules for your organization

Good luck! 🚀
