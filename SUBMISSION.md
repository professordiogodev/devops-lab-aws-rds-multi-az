# Submission

Fork URL: <!-- paste the URL of your fork here -->

## Files to commit

- [ ] `notes.md` with your commands and what you saw (optional)

## Questions

Answer in your own words. Where a question asks for output, paste it in a code block.

### Q1. Paste `aws rds describe-db-instances` (the key fields) for your database. What do MultiAZ, StorageEncrypted, PubliclyAccessible and BackupRetentionPeriod say about its safety?

**Your answer:**

<!-- replace this line with your answer -->

### Q2. Paste the subnet group and the security group rule. Why is the database in private subnets and why is the source a security group?

**Your answer:**

<!-- replace this line with your answer -->

### Q3. Force a failover and paste the zone before and after, and the event messages. What stayed the same for the application and why does that matter?

**Your answer:**

<!-- replace this line with your answer -->

### Q4. How long was the database unavailable during the failover? What would your app need so that it survives it (connection retries, DNS caching)?

**Your answer:**

<!-- replace this line with your answer -->

### Q5. Multi-AZ and a read replica both create a copy. Which one is for availability and which one is for scaling reads, and can a Multi-AZ standby serve queries?

**Your answer:**

<!-- replace this line with your answer -->

### Q6. Paste the output of `./verify.sh`. It must end with **ALL CHECKS PASSED**.

**Your answer:**

<!-- replace this line with your answer -->

### Q7. **Tear down.** Paste the output of `./verify-teardown.sh`. It must end with **TEARDOWN VERIFIED**.

**Your answer:**

<!-- replace this line with your answer -->
