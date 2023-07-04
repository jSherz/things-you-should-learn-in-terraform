[Previous Exercise] | [Home] | [Next Exercise]

[Previous Exercise]: ../01_setting-up-remote-state/README.md
[Home]: ../../README.md
[Next Exercise]: ../03_recovering-the-state-after-bad-changes/README.md

---

# Exercise 2 - pull and inspect the state

⚠️ **This exercise requires that you've completed exercise 1** ⚠️

It can be useful to view the raw Terraform state JSON, for example to see the
attribute values that have been read from AWS. We can pull the state down
into a file with the following command:

```bash
# Only if you haven't done this already
git clone git@github.com:jSherz/things-you-should-learn-in-terraform.git
cd exercises/01_setting-up-remote-state

terraform state pull > state.json
```

Open the `state.json` file in your editor and have a look.

## 🕵️ What can we find in the state?

### Resolved data source values

See if you can find this data source:

```terraform
data "aws_region" "this" {}
```

For me, this resolves to the following JSON in the state file:

```json
{
  "mode": "data",
  "type": "aws_region",
  "name": "this",
  "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
  "instances": [
    {
      "schema_version": 0,
      "attributes": {
        "description": "Europe (Ireland)",
        "endpoint": "ec2.eu-west-1.amazonaws.com",
        "id": "eu-west-1",
        "name": "eu-west-1"
      },
      "sensitive_attributes": []
    }
  ]
}
```

### Resource defaults

Let's have a look at the DynamoDB table we created for locking:

```terraform
resource "aws_dynamodb_table" "state_locks" {
  name = "my-tf-state-locks"

  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

We only specified three arguments and one block, but the state entry has a lot
more information:

```json
{
  "mode": "managed",
  "type": "aws_dynamodb_table",
  "name": "state_locks",
  "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
  "instances": [
    {
      "schema_version": 1,
      "attributes": {
        "arn": "arn:aws:dynamodb:eu-west-1:123456789012:table/my-tf-state-locks",
        "attribute": [
          {
            "name": "LockID",
            "type": "S"
          }
        ],
        "billing_mode": "PAY_PER_REQUEST",
        "deletion_protection_enabled": false,
        "global_secondary_index": [],
        "hash_key": "LockID",
        "id": "my-tf-state-locks",
        "local_secondary_index": [],
        "name": "my-tf-state-locks",
        "point_in_time_recovery": [
          {
            "enabled": false
          }
        ],
        "range_key": null,
        "read_capacity": 0,
        "replica": [],
        "restore_date_time": null,
        "restore_source_name": null,
        "restore_to_latest_time": null,
        "server_side_encryption": [],
        "stream_arn": "",
        "stream_enabled": false,
        "stream_label": "",
        "stream_view_type": "",
        "table_class": "STANDARD",
        "tags": null,
        "tags_all": {},
        "timeouts": null,
        "ttl": [
          {
            "attribute_name": "",
            "enabled": false
          }
        ],
        "write_capacity": 0
      },
      "sensitive_attributes": [],
      "private": "..."
    }
  ]
}
```

## Not convinced? 🧐 That's OK! Keep it in your back pocket

You may not have a use for reading the raw state yet - and that's OK. It's good
to know how to do it, just in case.

---

[Previous Exercise] | [Home] | [Next Exercise]
