import json, subprocess

result = subprocess.run(
    ["aws", "s3api", "list-object-versions", "--bucket", "fastory-dev-frontend", "--query", "{Objects: Versions[].{Key:Key,VersionId:VersionId}}", "--output", "json"],
    capture_output=True, text=True
)
data = json.loads(result.stdout)
if data.get("Objects"):
    delete_json = json.dumps(data)
    subprocess.run(
        ["aws", "s3api", "delete-objects", "--bucket", "fastory-dev-frontend", "--delete", delete_json],
        check=True
    )
    print("Versions deleted!")

# Also delete markers
result2 = subprocess.run(
    ["aws", "s3api", "list-object-versions", "--bucket", "fastory-dev-frontend", "--query", "{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}", "--output", "json"],
    capture_output=True, text=True
)
data2 = json.loads(result2.stdout)
if data2.get("Objects"):
    delete_json2 = json.dumps(data2)
    subprocess.run(
        ["aws", "s3api", "delete-objects", "--bucket", "fastory-dev-frontend", "--delete", delete_json2],
        check=True
    )
    print("Delete markers removed!")

print("S3 bucket is now empty!")
