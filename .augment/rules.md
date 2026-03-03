# Project Rules for terraform-aws-redis-enterprise

## Process Management
- Do not launch tasks without monitoring them - avoid getting stuck on potentially long-running tasks
- For long-running operations (terraform apply, etc.), use `wait=false` and periodically check progress with `read-process`
- Set reasonable timeouts and check task progress every 30-60 seconds
- If a task appears hung after multiple checks, investigate and report rather than waiting indefinitely

## Terraform Operations
- Always run `terraform validate` before `terraform apply`
- For terraform apply in tests, use `-auto-approve` flag
- Clean up test resources with `terraform destroy -auto-approve` after testing
- Never commit terraform.tfvars files with sensitive data

## Testing
- Test deployments should use minimal configurations to reduce costs
- Always clean up AWS resources after testing to avoid ongoing charges
- Check AWS costs/resources if a deployment seems stuck

