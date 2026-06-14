#!/usr/bin/env python3
"""
Reproduction Scripts for Common DevOps Scenarios
These scripts can be run locally or in CI/CD pipelines
"""

import os
import subprocess
import sys
import time
import logging
from datetime import datetime
from typing import List, Dict, Tuple

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s | %(levelname)-8s | %(message)s'
)
logger = logging.getLogger(__name__)

# ============================================================================
# Scenario 1: Test Build Pipeline Locally
# ============================================================================
def reproduce_build_pipeline():
    """
    Reproduces the complete build pipeline locally
    Useful for testing before pushing to CI/CD
    """
    logger.info("🔨 Starting local build pipeline reproduction")
    
    steps = [
        ("Restore dependencies", "dotnet restore --no-cache"),
        ("Build solution", "dotnet build SupportServices.slnx /warnaserror"),
        ("Run unit tests", "dotnet test SupportServices.slnx --filter 'TestCategory=Unit'"),
        ("Generate NuGet packages", "dotnet pack SupportServices.slnx"),
    ]
    
    start_time = time.time()
    
    for step_name, command in steps:
        logger.info(f"⚙️  {step_name}...")
        try:
            result = subprocess.run(command, shell=True, capture_output=True, text=True)
            if result.returncode != 0:
                logger.error(f"❌ {step_name} failed")
                logger.error(result.stderr)
                return False
            logger.info(f"✓ {step_name} completed")
        except Exception as e:
            logger.error(f"❌ Error during {step_name}: {e}")
            return False
    
    elapsed = time.time() - start_time
    logger.info(f"✓ Pipeline completed in {elapsed:.1f} seconds")
    return True

# ============================================================================
# Scenario 2: Bicep Template Deployment Test
# ============================================================================
def reproduce_bicep_deployment():
    """
    Reproduces Bicep deployment locally
    Useful for testing infrastructure changes before committing
    """
    logger.info("🏗️  Starting Bicep deployment reproduction")
    
    # Check Bicep CLI
    logger.info("Checking Bicep CLI installation...")
    result = subprocess.run("az bicep version", shell=True, capture_output=True)
    if result.returncode != 0:
        logger.error("Bicep CLI not installed. Run: az bicep install")
        return False
    
    logger.info("Validating Bicep templates...")
    bicep_files = [
        "bicep/main-shared.bicep",
        "bicep/main-service.bicep",
    ]
    
    for bicep_file in bicep_files:
        if not os.path.exists(bicep_file):
            logger.warning(f"Bicep file not found: {bicep_file}")
            continue
        
        logger.info(f"  Validating {bicep_file}...")
        result = subprocess.run(f"az bicep build --file {bicep_file}", 
                              shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            logger.error(f"❌ Validation failed for {bicep_file}")
            logger.error(result.stderr)
            return False
    
    logger.info("✓ All Bicep templates valid")
    return True

# ============================================================================
# Scenario 3: Test NuGet Package Restore
# ============================================================================
def reproduce_nuget_restore():
    """
    Tests NuGet restore with timing
    Useful for diagnosing slow builds
    """
    logger.info("📦 Starting NuGet restore reproduction")
    
    logger.info("Clearing NuGet cache...")
    subprocess.run("dotnet nuget locals all --clear", shell=True, capture_output=True)
    
    logger.info("Running restore without cache...")
    start = time.time()
    result = subprocess.run("dotnet restore --no-cache", shell=True, capture_output=True, text=True)
    no_cache_time = time.time() - start
    
    if result.returncode != 0:
        logger.error("❌ Restore failed")
        logger.error(result.stderr)
        return False
    
    logger.info(f"First restore (no cache): {no_cache_time:.1f}s")
    
    logger.info("Running restore with cache...")
    start = time.time()
    result = subprocess.run("dotnet restore", shell=True, capture_output=True, text=True)
    cache_time = time.time() - start
    
    logger.info(f"Second restore (cached): {cache_time:.1f}s")
    logger.info(f"Cache speedup: {no_cache_time/cache_time:.1f}x")
    
    return True

# ============================================================================
# Scenario 4: Test Build Caching Effectiveness
# ============================================================================
def reproduce_build_cache_test():
    """
    Tests how effective build caching is
    First build vs. incremental build comparison
    """
    logger.info("🔄 Starting build cache test reproduction")
    
    # First clean build
    logger.info("Running clean build (no cache)...")
    subprocess.run("dotnet clean", shell=True, capture_output=True)
    
    start = time.time()
    result = subprocess.run("dotnet build", shell=True, capture_output=True, text=True)
    clean_build_time = time.time() - start
    
    if result.returncode != 0:
        logger.error("❌ Clean build failed")
        return False
    
    logger.info(f"Clean build time: {clean_build_time:.1f}s")
    
    # Incremental build (no changes)
    logger.info("Running incremental build (with cache)...")
    start = time.time()
    result = subprocess.run("dotnet build", shell=True, capture_output=True, text=True)
    incremental_build_time = time.time() - start
    
    logger.info(f"Incremental build time: {incremental_build_time:.1f}s")
    logger.info(f"Cache effectiveness: {(1 - incremental_build_time/clean_build_time) * 100:.1f}% faster")
    
    return True

# ============================================================================
# Scenario 5: Test Parallel Test Execution
# ============================================================================
def reproduce_parallel_test_execution():
    """
    Reproduces parallel vs sequential test execution
    Shows the benefit of parallel test runs
    """
    logger.info("⚡ Starting parallel test execution reproduction")
    
    # Sequential test run
    logger.info("Running tests sequentially...")
    start = time.time()
    result = subprocess.run(
        "dotnet test SupportServices.slnx /p:ParallelizeTestCollections=false",
        shell=True,
        capture_output=True,
        text=True
    )
    sequential_time = time.time() - start
    
    if result.returncode != 0:
        logger.warning("Sequential test run had failures")
    
    logger.info(f"Sequential test time: {sequential_time:.1f}s")
    
    # Parallel test run
    logger.info("Running tests in parallel...")
    start = time.time()
    result = subprocess.run(
        "dotnet test SupportServices.slnx /p:ParallelizeTestCollections=true",
        shell=True,
        capture_output=True,
        text=True
    )
    parallel_time = time.time() - start
    
    if result.returncode != 0:
        logger.warning("Parallel test run had failures")
    
    logger.info(f"Parallel test time: {parallel_time:.1f}s")
    logger.info(f"Parallel speedup: {sequential_time/parallel_time:.1f}x faster")
    
    return True

# ============================================================================
# Scenario 6: Test Service Deployment & Health Checks
# ============================================================================
def reproduce_deployment_and_health_check():
    """
    Reproduces deploying a service and checking its health
    """
    logger.info("🚀 Starting deployment & health check reproduction")
    
    services = ["Chat", "Search", "Refunds"]
    
    for service in services:
        logger.info(f"Deploying {service}...")
        time.sleep(1)  # Simulate deployment
        
        logger.info(f"Checking health of {service}...")
        max_retries = 5
        for attempt in range(1, max_retries + 1):
            try:
                # In real scenario, would do actual health check
                if attempt >= 3:  # Simulate success after 2 retries
                    logger.info(f"✓ {service} is healthy")
                    break
                else:
                    logger.warning(f"  Attempt {attempt}: Not ready yet...")
                    time.sleep(2)
            except Exception as e:
                if attempt == max_retries:
                    logger.error(f"❌ {service} health check failed after {max_retries} attempts")
                    return False
    
    logger.info("✓ All services deployed and healthy")
    return True

# ============================================================================
# Scenario 7: Test Resource Cleanup
# ============================================================================
def reproduce_resource_cleanup():
    """
    Simulates resource cleanup operations
    Useful for testing cleanup logic before actual execution
    """
    logger.info("🧹 Starting resource cleanup reproduction")
    
    resources = [
        "rg-test-001",
        "rg-test-002",
        "rg-test-003",
    ]
    
    logger.info(f"Found {len(resources)} resources to clean up")
    
    for resource in resources:
        logger.info(f"Deleting {resource}...")
        time.sleep(0.5)  # Simulate deletion
        logger.info(f"✓ Deleted {resource}")
    
    logger.info("✓ Cleanup completed")
    return True

# ============================================================================
# Scenario 8: Test Rollback Procedure
# ============================================================================
def reproduce_rollback_procedure():
    """
    Reproduces a blue-green deployment rollback scenario
    """
    logger.info("⚙️  Starting rollback procedure reproduction")
    
    logger.info("Current version in production (blue): v1.5.0")
    logger.info("New version deployed (green): v2.0.0")
    
    logger.info("Running health checks on green slot...")
    time.sleep(1)
    logger.info("❌ Green slot health check failed")
    
    logger.info("Initiating rollback to blue slot...")
    time.sleep(1)
    logger.info("Swapping traffic back to blue...")
    time.sleep(1)
    
    logger.info("✓ Rollback complete - traffic restored to v1.5.0")
    return True

# ============================================================================
# Scenario 9: Test Cost Analysis
# ============================================================================
def reproduce_cost_analysis():
    """
    Simulates cost analysis of deployed resources
    """
    logger.info("💰 Starting cost analysis reproduction")
    
    resources = {
        "App Service Plans": {"count": 12, "monthly_cost": 73},
        "Cosmos DB": {"count": 1, "monthly_cost": 500},
        "Storage Accounts": {"count": 3, "monthly_cost": 25},
        "Key Vaults": {"count": 2, "monthly_cost": 1},
        "Application Insights": {"count": 12, "monthly_cost": 24},
    }
    
    total_cost = 0
    logger.info("Resource Cost Breakdown:")
    logger.info("-" * 50)
    
    for resource_type, data in resources.items():
        cost = data["count"] * data["monthly_cost"]
        total_cost += cost
        logger.info(f"  {resource_type:.<30} ${cost:>8.2f}")
    
    logger.info("-" * 50)
    logger.info(f"  Total Monthly Cost:........... ${total_cost:>8.2f}")
    logger.info(f"  Annual Cost:.................. ${total_cost * 12:>8.2f}")
    
    return True

# ============================================================================
# Main Reproduction Runner
# ============================================================================
def main():
    """Run all reproduction scenarios"""
    scenarios = [
        ("Build Pipeline", reproduce_build_pipeline),
        ("Bicep Deployment", reproduce_bicep_deployment),
        ("NuGet Restore", reproduce_nuget_restore),
        ("Build Caching", reproduce_build_cache_test),
        ("Parallel Tests", reproduce_parallel_test_execution),
        ("Deployment & Health", reproduce_deployment_and_health_check),
        ("Resource Cleanup", reproduce_resource_cleanup),
        ("Rollback Procedure", reproduce_rollback_procedure),
        ("Cost Analysis", reproduce_cost_analysis),
    ]
    
    print("\n" + "="*60)
    print("   DevOps Scenario Reproduction Tool")
    print("="*60)
    print("\nAvailable scenarios:")
    for i, (name, _) in enumerate(scenarios, 1):
        print(f"  {i}. {name}")
    print(f"  {len(scenarios) + 1}. Run all scenarios")
    print("="*60 + "\n")
    
    choice = input("Select scenario (1-" + str(len(scenarios) + 1) + "): ").strip()
    
    try:
        choice = int(choice)
        if choice == len(scenarios) + 1:
            # Run all
            for name, func in scenarios:
                logger.info("\n" + "="*60)
                success = func()
                logger.info("="*60)
                if not success:
                    logger.warning(f"⚠️  {name} had issues")
        elif 1 <= choice <= len(scenarios):
            name, func = scenarios[choice - 1]
            logger.info("\n" + "="*60)
            func()
            logger.info("="*60)
        else:
            print("Invalid choice")
    except ValueError:
        print("Invalid input")

if __name__ == "__main__":
    main()
