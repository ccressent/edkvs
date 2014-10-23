defmodule EDKVS.BucketTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, bucket} = EDKVS.Bucket.start_link
    {:ok, bucket: bucket}
  end

  test "stores values by key", %{bucket: bucket} do
    assert EDKVS.Bucket.get(bucket, "milk") == nil

    EDKVS.Bucket.put(bucket, "milk", 3)
    assert EDKVS.Bucket.get(bucket, "milk") == 3
  end

  test "deletes values by key", %{bucket: bucket} do
    EDKVS.Bucket.put(bucket, "milk", 3)
    EDKVS.Bucket.delete(bucket, "milk")
    assert EDKVS.Bucket.get(bucket, "milk") == nil
  end
end
