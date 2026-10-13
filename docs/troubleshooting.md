# Troubleshooting and Validation

This document records observed implementation results, an authentication error encountered during setup, planned troubleshooting tests, and potential failure scenarios.

## 1. AWS CLI Authentication Error

**Status:** Encountered during setup; authentication subsequently succeeded.

### Symptom

The following command initially returned `InvalidClientTokenId`:

```bash
aws sts get-caller-identity
```

AWS reported that the security token included in the request was invalid.

### Investigation and Resolution

A new AWS account was created after earlier AWS project work. The CLI was subsequently configured with credentials associated with the new IAM identity.

The identity command later succeeded.

### Verification

```bash
aws sts get-caller-identity
```

**Root-cause limitation:** The precise reason the original credentials were rejected was not independently isolated. Therefore, this document does not claim that expiration was conclusively established as the cause.

---

## 2. Nginx Web Server Verification

**Status:** Implemented and verified through the webpage screenshot.

### Objective

Confirm that the EC2 instance serves the custom webpage.

### Commands

```bash
sudo systemctl is-active nginx
curl -I http://localhost
```

### Expected Results

- Nginx reports `active`.
- The HTTP endpoint returns `200 OK`.

The custom webpage was opened through the EC2 public IPv4 address.

### Evidence

See `../screenshots/nginx_webpage.png`.

---

## 3. S3 Upload Using an EC2 IAM Role

**Status:** Implemented and verified.

### Objective

Upload a test file from EC2 to S3 using the attached IAM role instead of hardcoded AWS credentials.

### Configuration

- Bucket: `aws-infra-demo-buc`
- Object: `test.txt`
- IAM role: `EC2CloudMonitoringRole`
- IAM policy: `EC2ProjectS3UploadPolicy`

### Commands

```bash
echo "S3 upload successful from EC2 using an IAM role" > test.txt

aws s3 cp test.txt s3://aws-infra-demo-buc/test.txt

aws s3 ls s3://aws-infra-demo-buc/

cat test.txt
```

### Observed Result

The S3 object listing displayed `test.txt`, and the local file contents were displayed successfully.

### Evidence

See `../screenshots/s3_upload.png`.

---

## 4. CloudWatch Metrics and Alarm

**Status:** Implemented and verified through screenshots.

### Metric

- Namespace: `AWS/EC2`
- Metric: `CPUUtilization`
- Statistic: Average
- Period: 5 minutes

### Alarm

- Name: `EC2-High-CPU-Alert`
- Condition: CPU utilization greater than 70%
- Evaluation: One datapoint within five minutes

### Observed Result

The CPU utilization graph displayed metric data points. The alarm screenshot subsequently showed the alarm in the `OK` state.

### Limitation

The alarm was created without notification actions. No email notification was configured.

### Evidence

- `../screenshots/cloudwatch_metrics.png`
- `../screenshots/cloudwatch_alarm.png`

---

## 5. Nginx Failure and Recovery Test

**Status:** Pending execution and verification.

This test must not be described as completed until the commands have actually been run and the results observed.

### Procedure

1. Check the initial Nginx service status.
2. Verify the local HTTP endpoint.
3. Stop Nginx deliberately.
4. Confirm that the HTTP request fails.
5. Restart Nginx.
6. Confirm that the service is active and the HTTP endpoint responds successfully.

### Commands

```bash
sudo systemctl is-active nginx
curl -I http://localhost

sudo systemctl stop nginx
curl -I --max-time 5 http://localhost

sudo systemctl start nginx
sudo systemctl is-active nginx
curl -I http://localhost
```

### Expected Results

- Before stopping Nginx, the endpoint responds successfully.
- While Nginx is stopped, the HTTP request fails.
- After restarting Nginx, the service is active and the HTTP endpoint returns `200 OK`.

### Actual Result

Update this section after running the test. Record any deviations from the expected results.

---

## 6. Potential Failure Scenarios

The following scenarios are documented for future investigation. They have not necessarily been reproduced.

### Scenario A: Webpage Unavailable

Possible checks:

```bash
sudo systemctl status nginx
sudo journalctl -u nginx --no-pager -n 50
curl -I http://localhost
```

If the local endpoint works but external access fails, inspect:

- Security group inbound rules
- Subnet route table
- Internet gateway configuration
- Public IPv4 address assignment

### Scenario B: S3 Access Denied

Possible checks:

```bash
aws sts get-caller-identity
aws s3 ls s3://aws-infra-demo-buc/
```

Investigate:

- IAM role attachment
- IAM policy actions and resource ARNs
- Bucket name and region
- Bucket policies and applicable restrictions

### Scenario C: CloudWatch Alarm Not Evaluating

Inspect:

- Metric namespace and name
- EC2 instance identifier
- Alarm threshold and evaluation period
- Available datapoints
- Missing-data treatment
- Alarm history and state reason

Standard EC2 monitoring normally publishes metrics at five-minute intervals.

---

## Lessons Learned

- Use IAM roles instead of hardcoded AWS credentials on EC2.
- Scope IAM permissions to the required resources and actions.
- Verify application health locally before investigating network access.
- Use CloudWatch metrics and alarms to observe infrastructure health.
- Distinguish between verified tests and potential failure scenarios.
- Document the observed result rather than assuming a test passed.