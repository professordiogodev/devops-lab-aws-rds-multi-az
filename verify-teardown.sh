#!/usr/bin/env bash
# Proves the lab left nothing in AWS. Run with: ./verify-teardown.sh
set -u
ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || { echo "No working AWS credentials." >&2; exit 1; }
H=$(bash "$(dirname "$0")/.lab/handle.sh") || exit 1
echo "Checking account $ACCOUNT (handle $H), region $(aws configure get region)"
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
check "no database clippy-db-$H (a running database bills every hour)" bash -c "! aws rds describe-db-instances --db-instance-identifier clippy-db-$H >/dev/null 2>&1"
check "no database snapshot or automated backup of clippy-db-$H" bash -c "[ -z \"\$(aws rds describe-db-snapshots --db-instance-identifier clippy-db-$H --query \"DBSnapshots[?Status!='deleting'].DBSnapshotIdentifier\" --output text)\" ]"
check "no DB subnet group clippy-db-$H" bash -c "! aws rds describe-db-subnet-groups --db-subnet-group-name clippy-db-$H >/dev/null 2>&1"
check "no security groups named clippy-db-$H or clippy-app-$H" bash -c "[ -z \"\$(aws ec2 describe-security-groups --filters Name=group-name,Values=clippy-db-$H,clippy-app-$H --query 'SecurityGroups[].GroupId' --output text)\" ]"
check "no secret left from the database (RDS-managed master password)" bash -c "[ -z \"\$(aws secretsmanager list-secrets --query \"SecretList[?starts_with(Name, 'rds!db-')]|[?Tags[?Key=='aws:rds:primaryDBInstanceArn' && ends_with(Value, ':db:clippy-db-$H')]].Name\" --output text)\" ]"
echo
if [ "$failn" -eq 0 ]; then echo "TEARDOWN VERIFIED ($pass/$pass) in account $ACCOUNT"; else echo "NOT CLEAN: $failn leftover(s). Remove them and run this again."; fi
exit "$failn"
