#!/usr/bin/env python3
import json, os, re, subprocess, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
os.chdir(ROOT)
passed = failed = 0


def check(desc, ok, hint=""):
    global passed, failed
    if ok:
        passed += 1; print("PASS  " + desc)
    else:
        failed += 1; print("FAIL  " + desc + (("   -> " + hint) if hint else ""))


def aws(*a):
    try:
        return json.loads(subprocess.check_output(("aws",) + a + ("--output", "json"), stderr=subprocess.DEVNULL, timeout=90) or "null")
    except Exception:
        return None


print("== Your repository ==")
r = subprocess.run("git grep -lEi 'AKIA[0-9A-Z]{16}|MasterUserPassword|master-user-password' -- . ':!.lab' ':!verify.sh' ':!LAB.md' ':!README.md' ':!SUBMISSION.md'", shell=True, capture_output=True, text=True).stdout.strip()
check("no AWS key or database password in the repository", r == "", r)

print("== The database ==")
d = (aws("rds", "describe-db-instances", "--db-instance-identifier", "clippy-db") or {}).get("DBInstances", [None])[0]
check("a database named clippy-db exists and is available", bool(d) and d["DBInstanceStatus"] == "available", "status: %s" % (d or {}).get("DBInstanceStatus"))
if not d:
    print("\nNothing else can be checked.\n%d check(s) failed, %d passed" % (failed, passed)); sys.exit(1)
check("engine PostgreSQL, a small class (db.t3 or db.t4g) and gp3 or gp2 storage", d["Engine"] == "postgres" and re.match(r"db\.(t3|t4g)\.", d["DBInstanceClass"]) is not None and d.get("StorageType") in ("gp3", "gp2"))
check("Multi-AZ is on (a standby in a second zone)", d.get("MultiAZ") is True)
check("storage is encrypted", d.get("StorageEncrypted") is True)
check("the database is NOT publicly accessible", d.get("PubliclyAccessible") is False)
check("automated backups are kept at least 7 days", d.get("BackupRetentionPeriod", 0) >= 7)
check("the master password is managed by AWS (Secrets Manager), not typed by you", bool(d.get("MasterUserSecret")))
check("tagged lab=aws-rds-multi-az", any(t["Key"] == "lab" and t["Value"] == "aws-rds-multi-az" for t in (aws("rds", "list-tags-for-resource", "--resource-name", d["DBInstanceArn"]) or {}).get("TagList", [])))
sg = d.get("DBSubnetGroup", {})
azs = {s["SubnetAvailabilityZone"]["Name"] for s in sg.get("Subnets", [])}
check("the subnet group covers at least 2 availability zones", len(azs) >= 2, "found %s" % sorted(azs))

print("== The network around it ==")
ids = [g["VpcSecurityGroupId"] for g in d.get("VpcSecurityGroups", [])]
rules = (aws("ec2", "describe-security-group-rules", "--filters", "Name=group-id,Values=" + ",".join(ids)) or {}).get("SecurityGroupRules", []) if ids else []
ing = [x for x in rules if not x["IsEgress"]]
app = ((aws("ec2", "describe-security-groups", "--filters", "Name=group-name,Values=clippy-app") or {}).get("SecurityGroups") or [{}])[0].get("GroupId")
check("the database accepts exactly one thing: port 5432 from the clippy-app security group",
      len(ing) == 1 and ing[0]["FromPort"] == 5432 and ing[0]["ToPort"] == 5432 and ing[0].get("ReferencedGroupInfo", {}).get("GroupId") == app and bool(app))
check("nothing is open to a CIDR range (no 0.0.0.0/0, no /16)", not any(x.get("CidrIpv4") or x.get("CidrIpv6") for x in ing))

print("== The failover you forced ==")
ev = (aws("rds", "describe-events", "--source-identifier", "clippy-db", "--source-type", "db-instance", "--duration", "1440") or {}).get("Events", [])
msgs = " | ".join(e["Message"] for e in ev)
check("RDS recorded a completed Multi-AZ failover for clippy-db in the last 24 hours", "Multi-AZ instance failover completed" in msgs, "run: aws rds reboot-db-instance --db-instance-identifier clippy-db --force-failover")

print()
print(("ALL CHECKS PASSED (%d/%d)" % (passed, passed)) if failed == 0 else ("%d check(s) failed, %d passed" % (failed, passed)))
sys.exit(1 if failed else 0)
