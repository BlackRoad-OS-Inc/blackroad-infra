#!/usr/bin/env python3
"""
GitHub Actions Workflow Health Analyzer
Comprehensive health report for BlackRoad-OS organization workflows
"""

import json
import subprocess
import sys
from collections import defaultdict, Counter
from datetime import datetime
from typing import Dict, List, Tuple

class WorkflowHealthAnalyzer:
    def __init__(self):
        self.repos = [
            "blackroad-os-infra",
            "blackroad",
            "blackroad-app",
            "blackroad-agents",
            "blackroad-os-brand",
            "BlackRoad-Public",
            "BlackRoad-Private"
        ]
        self.all_runs = []
        self.workflow_stats = defaultdict(lambda: {"success": 0, "failure": 0, "cancelled": 0, "total": 0})
        self.repo_stats = defaultdict(lambda: {"success": 0, "failure": 0, "cancelled": 0, "total": 0})

    def fetch_workflow_runs(self, repo: str, limit: int = 100) -> List[Dict]:
        """Fetch workflow runs for a repository"""
        cmd = [
            "gh", "run", "list",
            "--repo", f"BlackRoad-OS/{repo}",
            "--limit", str(limit),
            "--json", "conclusion,name,status,startedAt,workflowName,databaseId"
        ]

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            if result.returncode == 0:
                runs = json.loads(result.stdout)
                # Add repo name to each run
                for run in runs:
                    run['repo'] = repo
                return runs
            else:
                print(f"⚠️  Warning: Failed to fetch runs for {repo}: {result.stderr}", file=sys.stderr)
                return []
        except Exception as e:
            print(f"⚠️  Error fetching {repo}: {str(e)}", file=sys.stderr)
            return []

    def collect_all_runs(self):
        """Collect workflow runs from all repositories"""
        print("🔍 Fetching workflow runs from all repositories...\n")
        for repo in self.repos:
            print(f"  📦 {repo}...", end=" ")
            runs = self.fetch_workflow_runs(repo)
            self.all_runs.extend(runs)
            print(f"{len(runs)} runs")

        print(f"\n✅ Total runs collected: {len(self.all_runs)}\n")

    def analyze_workflows(self):
        """Analyze workflow statistics"""
        for run in self.all_runs:
            workflow_name = run.get('workflowName', 'Unknown')
            conclusion = run.get('conclusion', 'in_progress')
            repo = run.get('repo', 'unknown')

            # Skip queued/in_progress runs for statistics
            if not conclusion or conclusion == '':
                conclusion = 'in_progress'
                continue

            # Update workflow stats
            self.workflow_stats[workflow_name][conclusion] += 1
            self.workflow_stats[workflow_name]['total'] += 1

            # Update repo stats
            self.repo_stats[repo][conclusion] += 1
            self.repo_stats[repo]['total'] += 1

    def calculate_success_rate(self, stats: Dict) -> float:
        """Calculate success rate percentage"""
        total = stats['total']
        if total == 0:
            return 0.0
        return (stats['success'] / total) * 100

    def get_failure_rate(self, stats: Dict) -> float:
        """Calculate failure rate percentage"""
        total = stats['total']
        if total == 0:
            return 0.0
        return (stats['failure'] / total) * 100

    def identify_problematic_workflows(self, threshold: float = 50.0) -> List[Tuple[str, Dict, float]]:
        """Identify workflows with failure rates above threshold"""
        problematic = []

        for workflow, stats in self.workflow_stats.items():
            if stats['total'] < 3:  # Skip workflows with very few runs
                continue

            failure_rate = self.get_failure_rate(stats)
            if failure_rate >= threshold:
                problematic.append((workflow, stats, failure_rate))

        # Sort by failure rate descending
        problematic.sort(key=lambda x: x[2], reverse=True)
        return problematic

    def identify_always_failing_workflows(self) -> List[Tuple[str, Dict]]:
        """Identify workflows that ALWAYS fail (100% failure rate)"""
        always_failing = []

        for workflow, stats in self.workflow_stats.items():
            if stats['total'] >= 3 and stats['success'] == 0 and stats['failure'] > 0:
                always_failing.append((workflow, stats))

        # Sort by total runs descending
        always_failing.sort(key=lambda x: x[1]['total'], reverse=True)
        return always_failing

    def identify_self_healing_status(self) -> Dict:
        """Check status of self-healing workflows"""
        self_healing_patterns = [
            "self-healing",
            "auto-heal",
            "auto-fix",
            "autonomous",
            "self heal"
        ]

        self_healing_workflows = {}

        for workflow, stats in self.workflow_stats.items():
            workflow_lower = workflow.lower()
            if any(pattern in workflow_lower for pattern in self_healing_patterns):
                success_rate = self.calculate_success_rate(stats)
                self_healing_workflows[workflow] = {
                    'stats': stats,
                    'success_rate': success_rate,
                    'status': 'working' if success_rate > 50 else 'stuck/broken'
                }

        return self_healing_workflows

    def identify_orphaned_workflows(self) -> List[str]:
        """Identify workflows that exist in .github/workflows but never run"""
        # Get all workflows from blackroad-os-infra
        cmd = [
            "gh", "workflow", "list",
            "--repo", "BlackRoad-OS/blackroad-os-infra",
            "--json", "name,state"
        ]

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            if result.returncode == 0:
                all_workflows = json.loads(result.stdout)
                workflow_names = {w['name'] for w in all_workflows if w.get('state') == 'active'}

                # Compare with workflows that have actually run
                run_workflows = set(self.workflow_stats.keys())

                # Orphaned = defined but never run (or very rarely)
                orphaned = []
                for wf in workflow_names:
                    if wf not in run_workflows:
                        orphaned.append(wf)
                    elif self.workflow_stats[wf]['total'] < 2:  # Less than 2 runs
                        orphaned.append(f"{wf} (rarely runs)")

                return orphaned
        except Exception as e:
            print(f"⚠️  Could not fetch workflow list: {e}", file=sys.stderr)
            return []

    def generate_report(self):
        """Generate comprehensive health report"""
        print("=" * 80)
        print("🏥 GITHUB ACTIONS WORKFLOW HEALTH REPORT")
        print("   BlackRoad-OS Organization")
        print("=" * 80)
        print()

        # Overall statistics
        total_runs = len([r for r in self.all_runs if r.get('conclusion')])
        total_success = sum(stats['success'] for stats in self.workflow_stats.values())
        total_failure = sum(stats['failure'] for stats in self.workflow_stats.values())
        total_cancelled = sum(stats['cancelled'] for stats in self.workflow_stats.values())

        overall_success_rate = (total_success / total_runs * 100) if total_runs > 0 else 0
        overall_failure_rate = (total_failure / total_runs * 100) if total_runs > 0 else 0

        print("📊 OVERALL STATISTICS")
        print("-" * 80)
        print(f"Total Workflow Runs Analyzed:  {total_runs}")
        print(f"Total Unique Workflows:        {len(self.workflow_stats)}")
        print(f"Total Repositories:            {len(self.repos)}")
        print()
        print(f"✅ Success:   {total_success:4d} runs ({overall_success_rate:5.1f}%)")
        print(f"❌ Failure:   {total_failure:4d} runs ({overall_failure_rate:5.1f}%)")
        print(f"🚫 Cancelled: {total_cancelled:4d} runs")
        print()

        # Repository breakdown
        print("📦 PER-REPOSITORY BREAKDOWN")
        print("-" * 80)
        for repo in sorted(self.repo_stats.keys(), key=lambda r: self.repo_stats[r]['total'], reverse=True):
            stats = self.repo_stats[repo]
            success_rate = self.calculate_success_rate(stats)
            failure_rate = self.get_failure_rate(stats)

            status_emoji = "🟢" if success_rate > 70 else "🟡" if success_rate > 40 else "🔴"

            print(f"{status_emoji} {repo:30s}  Total: {stats['total']:3d}  "
                  f"Success: {success_rate:5.1f}%  Failure: {failure_rate:5.1f}%")
        print()

        # Top 10 failing workflows
        print("🔥 TOP 10 MOST PROBLEMATIC WORKFLOWS")
        print("-" * 80)
        problematic = self.identify_problematic_workflows(threshold=30.0)[:10]

        if not problematic:
            print("✅ No highly problematic workflows found!")
        else:
            for i, (workflow, stats, failure_rate) in enumerate(problematic, 1):
                print(f"{i:2d}. {workflow}")
                print(f"    Failure Rate: {failure_rate:5.1f}% ({stats['failure']}/{stats['total']} runs)")
                print(f"    Success: {stats['success']}  Failure: {stats['failure']}  Cancelled: {stats['cancelled']}")
                print()

        # Always failing workflows
        print("💀 ALWAYS FAILING WORKFLOWS (100% Failure Rate)")
        print("-" * 80)
        always_failing = self.identify_always_failing_workflows()

        if not always_failing:
            print("✅ No workflows with 100% failure rate!")
        else:
            for workflow, stats in always_failing[:15]:  # Top 15
                print(f"❌ {workflow}")
                print(f"   {stats['failure']} failures, 0 successes")
                print()

        # Self-healing workflow status
        print("🤖 SELF-HEALING WORKFLOW STATUS")
        print("-" * 80)
        self_healing = self.identify_self_healing_status()

        if not self_healing:
            print("⚠️  No self-healing workflows detected")
        else:
            for workflow, data in self_healing.items():
                stats = data['stats']
                status_emoji = "✅" if data['status'] == 'working' else "🔴"
                print(f"{status_emoji} {workflow}")
                print(f"   Success Rate: {data['success_rate']:5.1f}%  "
                      f"Status: {data['status'].upper()}")
                print(f"   Total: {stats['total']}  Success: {stats['success']}  "
                      f"Failure: {stats['failure']}")
                print()

        # Pattern analysis
        print("🔍 FAILURE PATTERN ANALYSIS")
        print("-" * 80)
        self.analyze_failure_patterns()
        print()

        # Recommendations
        print("💡 RECOMMENDATIONS")
        print("-" * 80)
        self.generate_recommendations(always_failing, self_healing)
        print()

    def analyze_failure_patterns(self):
        """Analyze patterns in failing workflows"""
        # Categorize workflows by type
        categories = {
            'deployment': ['deploy', 'cloudflare', 'railway', 'pages', 'multi-cloud'],
            'ci_cd': ['ci', 'test', 'build', 'lint'],
            'security': ['security', 'codeql', 'scan', 'compliance'],
            'automation': ['bot', 'auto', 'sync', 'label'],
            'self_healing': ['self-healing', 'auto-heal', 'auto-fix'],
            'monitoring': ['health', 'dashboard', 'monitor', 'observability']
        }

        category_stats = defaultdict(lambda: {'success': 0, 'failure': 0, 'total': 0})

        for workflow, stats in self.workflow_stats.items():
            workflow_lower = workflow.lower()
            categorized = False

            for category, keywords in categories.items():
                if any(keyword in workflow_lower for keyword in keywords):
                    category_stats[category]['success'] += stats['success']
                    category_stats[category]['failure'] += stats['failure']
                    category_stats[category]['total'] += stats['total']
                    categorized = True
                    break

            if not categorized:
                category_stats['other']['success'] += stats['success']
                category_stats['other']['failure'] += stats['failure']
                category_stats['other']['total'] += stats['total']

        print("Workflow Category Failure Rates:")
        print()
        for category in sorted(category_stats.keys()):
            stats = category_stats[category]
            if stats['total'] == 0:
                continue

            failure_rate = (stats['failure'] / stats['total'] * 100)
            status_emoji = "🟢" if failure_rate < 30 else "🟡" if failure_rate < 60 else "🔴"

            print(f"{status_emoji} {category.replace('_', ' ').title():20s}  "
                  f"Failure Rate: {failure_rate:5.1f}%  "
                  f"({stats['failure']}/{stats['total']} runs)")

    def generate_recommendations(self, always_failing, self_healing):
        """Generate actionable recommendations"""
        recommendations = []

        # Check overall health
        total_runs = sum(stats['total'] for stats in self.workflow_stats.values())
        total_failures = sum(stats['failure'] for stats in self.workflow_stats.values())
        overall_failure_rate = (total_failures / total_runs * 100) if total_runs > 0 else 0

        if overall_failure_rate > 70:
            recommendations.append(
                "🚨 CRITICAL: Overall failure rate is {:.1f}%. Immediate action required!\n"
                "   - Disable non-critical workflows temporarily\n"
                "   - Focus on fixing core CI/CD pipelines first\n"
                "   - Review workflow configurations for common issues".format(overall_failure_rate)
            )

        # Check self-healing workflows
        if self_healing:
            broken_self_healing = [w for w, d in self_healing.items() if d['status'] == 'stuck/broken']
            if broken_self_healing:
                recommendations.append(
                    "🤖 Self-healing workflows are BROKEN and may be in infinite loops:\n"
                    "   {}\n"
                    "   - Disable these workflows immediately\n"
                    "   - Review logs for root cause\n"
                    "   - Fix underlying issues before re-enabling".format(
                        '\n   '.join(f'- {w}' for w in broken_self_healing)
                    )
                )

        # Check always failing workflows
        if len(always_failing) > 10:
            recommendations.append(
                f"❌ {len(always_failing)} workflows have 100% failure rate:\n"
                "   - Archive or delete workflows that are no longer needed\n"
                "   - Fix critical workflows (deployment, CI/CD) first\n"
                "   - Consider disabling broken automation until fixed"
            )

        # Specific workflow type recommendations
        deployment_failures = sum(
            stats['failure'] for wf, stats in self.workflow_stats.items()
            if 'deploy' in wf.lower() or 'cloudflare' in wf.lower()
        )

        if deployment_failures > 20:
            recommendations.append(
                f"☁️  {deployment_failures} deployment workflow failures detected:\n"
                "   - Check Cloudflare/Railway API credentials\n"
                "   - Verify DNS configurations\n"
                "   - Review wrangler.toml files for correctness"
            )

        # Print recommendations
        if recommendations:
            for i, rec in enumerate(recommendations, 1):
                print(f"{i}. {rec}")
                print()
        else:
            print("✅ System is relatively healthy! Focus on addressing the top failing workflows.")
            print()

    def export_json_report(self, filename: str = "/Users/alexa/github-actions-health-report.json"):
        """Export detailed report as JSON"""
        report = {
            'generated_at': datetime.now().isoformat(),
            'total_runs': len(self.all_runs),
            'total_workflows': len(self.workflow_stats),
            'workflow_stats': dict(self.workflow_stats),
            'repo_stats': dict(self.repo_stats),
            'always_failing': [
                {'workflow': wf, 'stats': stats}
                for wf, stats in self.identify_always_failing_workflows()
            ],
            'self_healing_status': self.identify_self_healing_status()
        }

        with open(filename, 'w') as f:
            json.dump(report, f, indent=2)

        print(f"📄 Detailed JSON report exported to: {filename}")


def main():
    analyzer = WorkflowHealthAnalyzer()

    # Collect data
    analyzer.collect_all_runs()

    # Analyze
    analyzer.analyze_workflows()

    # Generate report
    analyzer.generate_report()

    # Export JSON
    analyzer.export_json_report()


if __name__ == "__main__":
    main()
