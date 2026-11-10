#!/usr/bin/env bash
# Proves the lab left nothing in AWS. Run with: ./verify-teardown.sh
set -u
ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || { echo "No working AWS credentials." >&2; exit 1; }
echo "Checking account $ACCOUNT, region $(aws configure get region)"
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
check "no database clippy-db (a running database bills every hour)" bash -c "! aws rds describe-db-instances --db-instance-identifier clippy-db >/dev/null 2>&1"
check "no database snapshot or automated backup of clippy-db" bash -c "[ -z \"\$(aws rds describe-db-snapshots --db-instance-identifier clippy-db --query 'DBSnapshots[].DBSnapshotIdentifier' --output text)\" ]"
check "no DB subnet group clippy-db" bash -c "! aws rds describe-db-subnet-groups --db-subnet-group-name clippy-db >/dev/null 2>&1"
check "no security groups named clippy-db or clippy-app" bash -c "[ -z \"\$(aws ec2 describe-security-groups --filters Name=group-name,Values=clippy-db,clippy-app --query 'SecurityGroups[].GroupId' --output text)\" ]"
check "no secret left from the database (RDS-managed master password)" bash -c "[ -z \"\$(aws secretsmanager list-secrets --query \"SecretList[?starts_with(Name, 'rds!db-')]|[?Tags[?Key=='aws:rds:primaryDBInstanceArn' && contains(Value, 'clippy-db')]].Name\" --output text)\" ]"
echo
if [ "$failn" -eq 0 ]; then echo "TEARDOWN VERIFIED ($pass/$pass) in account $ACCOUNT"; else echo "NOT CLEAN: $failn leftover(s). Remove them and run this again."; fi
exit "$failn"
