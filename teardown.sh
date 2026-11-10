#!/usr/bin/env bash
# Deletes the database, its subnet group and the security groups. Run with: ./teardown.sh
set -u
aws sts get-caller-identity >/dev/null 2>&1 || { echo "No working AWS credentials." >&2; exit 1; }
if aws rds describe-db-instances --db-instance-identifier clippy-db >/dev/null 2>&1; then
  echo "Deleting the database clippy-db (no final snapshot). This takes several minutes..."
  aws rds modify-db-instance --db-instance-identifier clippy-db --no-deletion-protection --apply-immediately >/dev/null 2>&1
  aws rds delete-db-instance --db-instance-identifier clippy-db --skip-final-snapshot --delete-automated-backups >/dev/null && aws rds wait db-instance-deleted --db-instance-identifier clippy-db && echo "  database deleted"
fi
aws rds delete-db-subnet-group --db-subnet-group-name clippy-db 2>/dev/null && echo "deleted subnet group clippy-db"
for n in clippy-db clippy-app; do
  for g in $(aws ec2 describe-security-groups --filters Name=group-name,Values=$n --query 'SecurityGroups[].GroupId' --output text); do
    aws ec2 delete-security-group --group-id "$g" 2>/dev/null && echo "deleted security group $n ($g)"
  done
done
echo "Now run ./verify-teardown.sh"
