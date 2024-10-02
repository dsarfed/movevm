/* (c) 2024 initia labs. Licensed under BUSL-1.1 */

#ifndef __LIBCOMPILER__
#define __LIBCOMPILER__

/* Generated with cbindgen:0.26.0 */

/* Warning, this file is autogenerated by cbindgen. Don't modify this manually. */

#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>


enum ErrnoValue {
  ErrnoValue_Success = 0,
  ErrnoValue_Other = 1,
};
typedef int32_t ErrnoValue;

/**
 * An optional Vector type that requires explicit creation and destruction
 * and can be sent via FFI.
 * It can be created from `Option<Vec<u8>>` and be converted into `Option<Vec<u8>>`.
 *
 * This type is always created in Rust and always dropped in Rust.
 * If Go code want to create it, it must instruct Rust to do so via the
 * [`new_unmanaged_vector`] FFI export. If Go code wants to consume its data,
 * it must create a copy and instruct Rust to destroy it via the
 * [`destroy_unmanaged_vector`] FFI export.
 *
 * An UnmanagedVector is immutable.
 *
 * ## Ownership
 *
 * Ownership is the right and the obligation to destroy an `UnmanagedVector`
 * exactly once. Both Rust and Go can create an `UnmanagedVector`, which gives
 * then ownership. Sometimes it is necessary to transfer ownership.
 *
 * ### Transfer ownership from Rust to Go
 *
 * When an `UnmanagedVector` was created in Rust using [`UnmanagedVector::new`], [`UnmanagedVector::default`]
 * or [`new_unmanaged_vector`], it can be passted to Go as a return value.
 * Rust then has no chance to destroy the vector anymore, so ownership is transferred to Go.
 * In Go, the data has to be copied to a garbage collected `[]byte`. Then the vector must be destroyed
 * using [`destroy_unmanaged_vector`].
 *
 * ### Transfer ownership from Go to Rust
 *
 * When Rust code calls into Go (using the vtable methods), return data or error messages must be created
 * in Go. This is done by calling [`new_unmanaged_vector`] from Go, which copies data into a newly created
 * `UnmanagedVector`. Since Go created it, it owns it. The ownership is then passed to Rust via the
 * mutable return value pointers. On the Rust side, the vector is destroyed using [`UnmanagedVector::consume`].
 *
 */
typedef struct {
  /**
   * True if and only if this is None. If this is true, the other fields must be ignored.
   */
  bool is_none;
  uint8_t *ptr;
  size_t len;
  size_t cap;
} UnmanagedVector;

/**
 * A view into an externally owned byte slice (Go `[]byte`).
 * Use this for the current call only. A view cannot be copied for safety reasons.
 * If you need a copy, use [`ByteSliceView::to_owned`].
 *
 * Go's nil value is fully supported, such that we can differentiate between nil and an empty slice.
 */
typedef struct {
  /**
   * True if and only if the byte slice is nil in Go. If this is true, the other fields must be ignored.
   */
  bool is_nil;
  const uint8_t *ptr;
  size_t len;
} ByteSliceView;

UnmanagedVector build_move_package(UnmanagedVector *errmsg, ByteSliceView compiler_args_payload);

UnmanagedVector clean_move_package(UnmanagedVector *errmsg,
                                   ByteSliceView compiler_args_payload,
                                   bool clean_cache,
                                   bool clean_byproduct,
                                   bool force);

UnmanagedVector coverage_bytecode_move_package(UnmanagedVector *errmsg,
                                               ByteSliceView compiler_args_payload,
                                               ByteSliceView coverage_opt_payload);

UnmanagedVector coverage_source_move_package(UnmanagedVector *errmsg,
                                             ByteSliceView compiler_args_payload,
                                             ByteSliceView coverage_opt_payload);

UnmanagedVector coverage_summary_move_package(UnmanagedVector *errmsg,
                                              ByteSliceView compiler_args_payload,
                                              ByteSliceView coverage_opt_payload);

UnmanagedVector create_new_move_package(UnmanagedVector *errmsg,
                                        ByteSliceView compiler_args_payload,
                                        ByteSliceView name_view,
                                        ByteSliceView movevm_version_view,
                                        bool use_minlib);

void destroy_unmanaged_vector(UnmanagedVector v);

UnmanagedVector docgen_move_package(UnmanagedVector *errmsg,
                                    ByteSliceView compiler_args_payload,
                                    ByteSliceView docgen_opt_payload);

UnmanagedVector new_unmanaged_vector(bool nil, const uint8_t *ptr, size_t length);

UnmanagedVector test_move_package(UnmanagedVector *errmsg,
                                  ByteSliceView compiler_args_payload,
                                  ByteSliceView test_opt_payload);

#endif /* __LIBCOMPILER__ */
