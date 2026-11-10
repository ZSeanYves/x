// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
#borrow(path)
extern "C" fn raw_flush(path : String, writable : Bool) -> Int32 = "timestamp_probe_flush"

///|
async test "sync_timestamp direct comparison without platform skips" {
  let path = "tmp_sync_timestamp_probe_\{@env.now()}.bin"
  let data = b"timestamp probe"
  @xfs.write_file(path, data, sync=NoSync)
  defer @xfs.remove_file(path)
  let observations : Array[String] = []
  let mut failures = 0
  for
    (name, read) in [
      ("x.default", () => @xfs.read_file(path)),
      ("x.sync_timestamp", () => @xfs.read_file(path, sync_timestamp=true)),
    ] {
    try {
      assert_eq(read(), data)
      observations.push("\{name}: OK")
    } catch {
      error => {
        failures += 1
        observations.push("\{name}: \{error}")
      }
    }
  }
  try {
    let file = @xfs.open(path, mode=ReadWrite)
    defer file.close()
    assert_eq(file.read_all(), data)
    file.sync()
    observations.push("x.read_write_sync: OK")
  } catch {
    error => {
      failures += 1
      observations.push("x.read_write_sync: \{error}")
    }
  }
  try {
    assert_eq(@async_fs.read_binary(path), data)
    observations.push("core_async.default: OK")
  } catch {
    error => {
      failures += 1
      observations.push("core_async.default: \{error}")
    }
  }
  try {
    assert_eq(@async_fs.read_binary(path, sync_timestamp=true), data)
    observations.push("core_async.sync_timestamp: OK")
  } catch {
    error => {
      failures += 1
      observations.push("core_async.sync_timestamp: \{error}")
    }
  }
  try {
    let file = @async_fs.open(path, mode=ReadWrite)
    defer file.close()
    assert_eq(file.read_all(), data)
    file.sync()
    observations.push("core_async.read_write_sync: OK")
  } catch {
    error => {
      failures += 1
      observations.push("core_async.read_write_sync: \{error}")
    }
  }
  let read_only = raw_flush(path, false)
  if read_only != -2147483648 {
    let read_write = raw_flush(path, true)
    observations.push("win32.read_only_flush: \{read_only}")
    observations.push("win32.read_write_flush: \{read_write}")
  }
  assert_eq(@xfs.read_file(path), data)
  let report = observations.join("\n")
  println(report)
  guard failures == 0 else { fail(report) }
}
