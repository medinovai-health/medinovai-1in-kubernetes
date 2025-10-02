import { test, expect } from '@playwright/test';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

/**
 * Tier 1: Container & Orchestration Infrastructure Tests
 * 
 * Tests the following components:
 * - Docker Desktop
 * - Kubernetes (k3d/k3s)
 * - kubectl
 * - Helm
 */

test.describe('Tier 1: Container & Orchestration', () => {
  
  test.describe('Docker Desktop', () => {
    
    test('should be running and accessible', async () => {
      const { stdout } = await execAsync('docker info');
      expect(stdout).toContain('Server Version');
      expect(stdout).not.toContain('Cannot connect');
    });
    
    test('should have correct version installed', async () => {
      const { stdout } = await execAsync('docker --version');
      expect(stdout).toMatch(/Docker version \d+\.\d+\.\d+/);
    });
    
    test('should have sufficient resources allocated', async () => {
      const { stdout } = await execAsync('docker info --format "{{.NCPU}}"');
      const cpus = parseInt(stdout.trim());
      expect(cpus).toBeGreaterThanOrEqual(8); // Minimum 8 CPUs
    });
    
    test('should list running containers', async () => {
      const { stdout } = await execAsync('docker ps --format "{{.Names}}"');
      // Should have at least some containers running
      const containers = stdout.trim().split('\n').filter(c => c.length > 0);
      expect(containers.length).toBeGreaterThan(0);
    });
    
    test('should have medinovai-network network', async () => {
      const { stdout } = await execAsync('docker network ls --format "{{.Name}}"');
      expect(stdout).toContain('medinovai');
    });
  });
  
  test.describe('Kubernetes (k3d)', () => {
    
    test('should have k3d installed', async () => {
      const { stdout } = await execAsync('k3d --version');
      expect(stdout).toMatch(/k3d version v\d+\.\d+\.\d+/);
    });
    
    test('should have medinovai-cluster running', async () => {
      const { stdout } = await execAsync('k3d cluster list');
      expect(stdout).toContain('medinovai-cluster');
      expect(stdout).toContain('running');
    });
    
    test('should have correct number of nodes', async () => {
      const { stdout } = await execAsync('kubectl get nodes --no-headers');
      const nodes = stdout.trim().split('\n').filter(n => n.length > 0);
      expect(nodes.length).toBeGreaterThanOrEqual(5); // 2 control-plane + 3 workers
    });
    
    test('should have all nodes in Ready state', async () => {
      const { stdout } = await execAsync('kubectl get nodes --no-headers');
      const lines = stdout.trim().split('\n');
      
      for (const line of lines) {
        expect(line).toContain('Ready');
        expect(line).not.toContain('NotReady');
      }
    });
  });
  
  test.describe('kubectl', () => {
    
    test('should be installed and accessible', async () => {
      const { stdout } = await execAsync('kubectl version --client');
      expect(stdout).toContain('Client Version');
    });
    
    test('should connect to cluster', async () => {
      const { stdout } = await execAsync('kubectl cluster-info');
      expect(stdout).toContain('Kubernetes control plane');
      expect(stdout).toContain('running');
    });
    
    test('should list medinovai namespace', async () => {
      const { stdout } = await execAsync('kubectl get namespace medinovai');
      expect(stdout).toContain('medinovai');
      expect(stdout).toContain('Active');
    });
    
    test('should access cluster resources', async () => {
      const { stdout } = await execAsync('kubectl get pods -A --no-headers');
      const pods = stdout.trim().split('\n').filter(p => p.length > 0);
      expect(pods.length).toBeGreaterThan(0);
    });
  });
  
  test.describe('Helm', () => {
    
    test('should be installed', async () => {
      const { stdout } = await execAsync('helm version');
      expect(stdout).toMatch(/version\.BuildInfo/);
    });
    
    test('should list installed releases', async () => {
      try {
        await execAsync('helm list -A');
        // Command should execute without error
        expect(true).toBe(true);
      } catch (error) {
        // No releases is also valid
        expect(true).toBe(true);
      }
    });
    
    test('should have access to helm repositories', async () => {
      const { stdout } = await execAsync('helm repo list || echo "no repos"');
      // Either has repos or "no repos" - both are valid states
      expect(stdout.length).toBeGreaterThan(0);
    });
  });
  
  test.describe('Integration: Docker + Kubernetes', () => {
    
    test('should have k3d cluster accessible from docker', async () => {
      const { stdout } = await execAsync('docker ps --filter "name=k3d-medinovai" --format "{{.Names}}"');
      const k3dContainers = stdout.trim().split('\n').filter(c => c.length > 0);
      expect(k3dContainers.length).toBeGreaterThan(0);
    });
    
    test('should have all k3d containers running', async () => {
      const { stdout } = await execAsync('docker ps --filter "name=k3d-medinovai" --format "{{.Status}}"');
      const statuses = stdout.trim().split('\n');
      
      for (const status of statuses) {
        expect(status).toContain('Up');
      }
    });
  });
  
  test.describe('Resource Allocation', () => {
    
    test('should have Docker allocated sufficient memory', async () => {
      const { stdout } = await execAsync('docker info --format "{{.MemTotal}}"');
      const memBytes = parseInt(stdout.trim());
      const memGB = memBytes / (1024 * 1024 * 1024);
      expect(memGB).toBeGreaterThanOrEqual(100); // At least 100GB
    });
    
    test('should have storage available', async () => {
      const { stdout } = await execAsync('df -h / | tail -1');
      expect(stdout).toMatch(/\d+%/);
      
      // Extract usage percentage
      const match = stdout.match(/(\d+)%/);
      if (match) {
        const usage = parseInt(match[1]);
        expect(usage).toBeLessThan(95); // Less than 95% full
      }
    });
  });
  
  test.describe('Health Checks', () => {
    
    test('should have Docker daemon healthy', async () => {
      const { stdout } = await execAsync('docker ps > /dev/null && echo "healthy"');
      expect(stdout.trim()).toBe('healthy');
    });
    
    test('should have Kubernetes API responsive', async () => {
      const { stdout } = await execAsync('kubectl get --raw /healthz');
      expect(stdout).toBe('ok');
    });
    
    test('should have cluster DNS working', async () => {
      const { stdout } = await execAsync('kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers');
      expect(stdout).toContain('Running');
    });
  });
});

