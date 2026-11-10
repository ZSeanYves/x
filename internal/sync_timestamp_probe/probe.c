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

#include <stdint.h>
#include <moonbit.h>
#ifdef _WIN32
#include <windows.h>
#endif

// Zero means successful flush, positive means a flush error, negative means an
// open error. INT32_MIN indicates that the host is not Windows.
MOONBIT_FFI_EXPORT int32_t timestamp_probe_flush(moonbit_string_t path,
                                               int32_t writable) {
#ifdef _WIN32
  HANDLE handle = CreateFileW(
      (LPCWSTR)path, GENERIC_READ | (writable ? GENERIC_WRITE : 0),
      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL,
      OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
  if (handle == INVALID_HANDLE_VALUE) return -(int32_t)GetLastError();
  int32_t error = FlushFileBuffers(handle) ? 0 : (int32_t)GetLastError();
  CloseHandle(handle);
  return error;
#else
  (void)path;
  (void)writable;
  return INT32_MIN;
#endif
}
