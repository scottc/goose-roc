## Glue script: generate Goose bindings for Roc hosted symbols + reflected types.
## Target: https://github.com/aardappel/goose
##
## Emits: roc_platform_abi.goose
app [make_glue] { pf: platform glue }

import pf.Types
import pf.File
import pf.TypeRepr
import pf.AbiLayout
import pf.AbiFieldLayout
import pf.AbiTagLayout
import pf.AbiWidth
import pf.ArgShape
import pf.GlueInput
import pf.HostedFunctionInfo
import pf.TypeNamePlan
import pf.RecordRepr
import pf.TagUnionRepr
import pf.ProvidesEntry
import pf.TypeTable
import pf.RocName

make_glue : List(Types) -> Try(List(File), Str)
make_glue = |types_list| {
    input = GlueInput.from_types(types_list)
    type_table = TypeTable.from_list(input.types)
    content = generate_goose_file(input.hosted_functions, type_table, input.provides_entries)

    Ok([{ name: "roc_platform_abi.goose", content: content }])
}

# =============================================================================
# Names
# =============================================================================

name_to_struct_name : Str -> Str
name_to_struct_name = |name| RocName.from_str(name).to_pascal_clean()

name_to_snake : Str -> Str
name_to_snake = |name| RocName.from_str(name).to_lower_snake()

name_to_field : Str -> Str
name_to_field = |name| {
    raw = RocName.from_str(name).to_lower_snake()
    if raw == "pad" or raw == "type" or raw == "fn" or raw == "import" {
        "${raw}_field"
    } else {
        raw
    }
}

duplicate_tag_union_names : TypeTable -> List(Str)
duplicate_tag_union_names = |type_table| type_table.duplicate_tag_union_names()

duplicate_record_names : TypeTable -> List(Str)
duplicate_record_names = |type_table| type_table.duplicate_record_names()

default_tag_union_struct_name : List(Str), U64, TagUnionRepr -> Str
default_tag_union_struct_name = |duplicate_names, type_id, tu| {
    base = name_to_struct_name(tu.name)
    if List.contains(duplicate_names, tu.name) {
        "${base}Type${U64.to_str(type_id)}"
    } else {
        base
    }
}

tag_union_struct_name : TypeNamePlan.PreferredNames, List(Str), U64, TagUnionRepr -> Str
tag_union_struct_name = |preferred_names, duplicate_names, type_id, tu| {
    preferred = preferred_names.lookup(type_id)
    if preferred.found {
        preferred.name
    } else {
        default_tag_union_struct_name(duplicate_names, type_id, tu)
    }
}

record_struct_name : List(Str), U64, RecordRepr -> Str
record_struct_name = |duplicate_names, type_id, rec| {
    base = name_to_struct_name(rec.name)
    if List.contains(duplicate_names, rec.name) {
        "${base}Type${U64.to_str(type_id)}"
    } else {
        base
    }
}

hosted_module_name_to_struct_name : Str -> Str
hosted_module_name_to_struct_name = |name|
    match List.first(Str.split_on(name, ".")) {
        Ok(module_name) => name_to_struct_name(module_name)
        Err(_) => crash "glue invariant violated: module name split produced no segments"
    }

# =============================================================================
# Preferred names
# =============================================================================

generated_type_names_goose : TypeTable, List(Str), List(Str) -> List(Str)
generated_type_names_goose = |type_table, duplicate_records, duplicate_tags| {
    var $names = []
    var $type_id = 0
    for type_info in type_table.entries() {
        match type_info.repr {
            RocRecord(rec) =>
                if rec.name != "" {
                    $names = $names.append(record_struct_name(duplicate_records, $type_id, rec))
                }
            RocTagUnion(tu) =>
                if List.len(tu.tags) >= 2 and tu.name != "" {
                    $names = $names.append(default_tag_union_struct_name(duplicate_tags, $type_id, tu))
                }
            _ => {}
        }
        $type_id = $type_id + 1
    }
    $names
}

type_name_root_alias_base : TypeTable, Str, U64 -> Str
type_name_root_alias_base = |type_table, fallback, type_id|
    match type_table.get(type_id) {
        RocRecord(rec) =>
            if rec.name != "" and !rec.anonymous {
                name_to_struct_name(rec.name)
            } else {
                fallback
            }
        RocTagUnion(tu) =>
            if tu.name != "" and tu.name != "Try" and tu.name != "IOErr" {
                name_to_struct_name(tu.name)
            } else {
                fallback
            }
        _ => fallback
    }

type_name_roots : List(HostedFunctionInfo), List(ProvidesEntry), TypeTable -> List(TypeNamePlan.Root)
type_name_roots = |hosted_functions, provides_list, type_table| {
    var $roots = []
    for func in hosted_functions {
        base = name_to_struct_name(func.name)
        module_base = hosted_module_name_to_struct_name(func.name)
        var $arg_idx = 0
        for arg_type_id in func.arg_type_ids {
            arg_fallback = "${base}Arg${U64.to_str($arg_idx)}"
            $roots = $roots.append({
                alias_base: type_name_root_alias_base(type_table, arg_fallback, arg_type_id),
                module_base,
                type_id: arg_type_id,
            })
            $arg_idx = $arg_idx + 1
        }
        $roots = $roots.append({
            alias_base: base,
            module_base,
            type_id: func.ret_type_id,
        })
    }
    for entry in provides_list {
        base = name_to_struct_name(entry.name)
        module_base = hosted_module_name_to_struct_name(entry.name)
        match entry.exported {
            ProvidedProcedure(func) => {
                var $arg_idx = 0
                for arg_type_id in func.args {
                    arg_fallback = "${base}Arg${U64.to_str($arg_idx)}"
                    $roots = $roots.append({
                        alias_base: type_name_root_alias_base(type_table, arg_fallback, arg_type_id),
                        module_base,
                        type_id: arg_type_id,
                    })
                    $arg_idx = $arg_idx + 1
                }
                $roots = $roots.append({
                    alias_base: base,
                    module_base,
                    type_id: func.ret,
                })
            }
            ProvidedData(type_id) => {
                $roots = $roots.append({
                    alias_base: type_name_root_alias_base(type_table, base, type_id),
                    module_base,
                    type_id,
                })
            }
        }
    }
    $roots
}

preferred_type_names : List(HostedFunctionInfo), List(ProvidesEntry), TypeTable, List(Str), List(Str) -> TypeNamePlan.PreferredNames
preferred_type_names = |hosted_functions, provides_list, type_table, duplicate_records, duplicate_tags|
    TypeNamePlan.from_table(type_table).preferred_names(
        generated_type_names_goose(type_table, duplicate_records, duplicate_tags),
        type_name_roots(hosted_functions, provides_list, type_table),
    )

# =============================================================================
# Type → Goose
# =============================================================================

type_id_to_goose : TypeTable, List(Str), List(Str), TypeNamePlan.PreferredNames, U64 -> Str
type_id_to_goose = |type_table, duplicate_records, duplicate_tags, preferred_names, type_id|
    type_repr_to_goose(type_table, duplicate_records, duplicate_tags, preferred_names, type_id, type_table.get(type_id))

type_repr_to_goose : TypeTable, List(Str), List(Str), TypeNamePlan.PreferredNames, U64, TypeRepr -> Str
type_repr_to_goose = |type_table, duplicate_records, duplicate_tags, preferred_names, type_id, type_repr| {
    match type_repr {
        RocBool => "bool"
        RocStr => "RocStr"
        RocUnit => "u8"
        RocU8 => "u8"
        RocU16 => "u16"
        RocU32 => "u32"
        RocU64 => "u64"
        RocU128 => "u64"
        RocI8 => "i8"
        RocI16 => "i16"
        RocI32 => "i32"
        RocI64 => "i64"
        RocI128 => "i64"
        RocF32 => "f32"
        RocF64 => "f64"
        RocDec => "RocDec"
        RocList(_) => "RocList"
        RocBox(_) => "u64"
        RocErasedCallable(_) => "u64"
        RocU8x16 => "RocVec128"
        RocI8x16 => "RocVec128"
        RocU16x8 => "RocVec128"
        RocI16x8 => "RocVec128"
        RocU32x4 => "RocVec128"
        RocI32x4 => "RocVec128"
        RocU64x2 => "RocVec128"
        RocI64x2 => "RocVec128"
        RocRecord(rec) =>
            if rec.name == "" {
                "u64"
            } else {
                record_struct_name(duplicate_records, type_id, rec)
            }
        RocTagUnion(tu) => resolve_tag_union_type(type_table, duplicate_records, duplicate_tags, preferred_names, type_id, tu)
        RocUnknown(_) => "u64"
    }
}

resolve_tag_union_type : TypeTable, List(Str), List(Str), TypeNamePlan.PreferredNames, U64, TagUnionRepr -> Str
resolve_tag_union_type = |type_table, duplicate_records, duplicate_tags, preferred_names, type_id, tu|
    match TypeTable.single_variant_payload(tu) {
        SinglePayload(payload_id) => type_id_to_goose(type_table, duplicate_records, duplicate_tags, preferred_names, payload_id)
        SingleNoPayload => "u8"
        NotSingleVariant =>
            if tu.name != "" {
                tag_union_struct_name(preferred_names, duplicate_tags, type_id, tu)
            } else {
                "u64"
            }
    }

# =============================================================================
# File assembly
# =============================================================================

generate_goose_file : List(HostedFunctionInfo), TypeTable, List(ProvidesEntry) -> Str
generate_goose_file = |hosted_functions, type_table, provides_list| {
    duplicate_records = duplicate_record_names(type_table)
    duplicate_tags = duplicate_tag_union_names(type_table)
    preferred_names = preferred_type_names(hosted_functions, provides_list, type_table, duplicate_records, duplicate_tags)

    file_header
        .concat(core_types_section)
        .concat(generate_type_decls(type_table, duplicate_records, duplicate_tags, preferred_names))
        .concat(runtime_symbols_section)
        .concat(generate_hosted_exports(hosted_functions, type_table, duplicate_records, duplicate_tags, preferred_names))
        .concat(generate_provides_externs(provides_list, type_table, duplicate_records, duplicate_tags, preferred_names))
        .concat(file_footer)
}

file_header : Str
file_header =
    \\// Generated by GooseGlue.roc — do not edit by hand.
    \\// Roc platform ABI bindings for Goose (aardappel/goose).
    \\//
    \\// Host still must define roc_alloc / roc_dealloc / roc_realloc / roc_dbg /
    \\// roc_expect_failed / roc_crashed, plus each export below.
    \\
    \\

core_types_section : Str
core_types_section =
    \\// ---- Core Roc value types (C ABI shapes) ----
    \\
    \\struct RocStr {
    \\    bytes: u64,
    \\    cap: u64,
    \\    len: u64,
    \\}
    \\
    \\struct RocList {
    \\    bytes: u64,
    \\    length: u64,
    \\    capacity_or_other: u64,
    \\}
    \\
    \\struct RocDec {
    \\    lo: u64,
    \\    hi: u64,
    \\}
    \\
    \\struct RocVec128 {
    \\    lo: u64,
    \\    hi: u64,
    \\}
    \\
    \\

runtime_symbols_section : Str
runtime_symbols_section =
    \\// ---- Fixed runtime symbols (host defines these) ----
    \\// export "roc_alloc" fn roc_alloc(size: u64, alignment: u32) -> u64
    \\// export "roc_dealloc" fn roc_dealloc(ptr: u64, alignment: u32)
    \\// export "roc_realloc" fn roc_realloc(ptr: u64, new_size: u64, old_size: u64, alignment: u32) -> u64
    \\// export "roc_dbg" fn roc_dbg(bytes: u64, len: u64)
    \\// export "roc_expect_failed" fn roc_expect_failed(bytes: u64, len: u64)
    \\// export "roc_crashed" fn roc_crashed(msg: u64)
    \\
    \\

file_footer : Str
file_footer =
    \\
    \\// ---- end of generated roc_platform_abi.goose ----
    \\

# =============================================================================
# Type declarations
# =============================================================================

abi_record_fields : AbiLayout -> List(AbiFieldLayout)
abi_record_fields = |abi_layout| abi_layout.record_fields()

generate_type_decls : TypeTable, List(Str), List(Str), TypeNamePlan.PreferredNames -> Str
generate_type_decls = |type_table, duplicate_records, duplicate_tags, preferred_names| {
    var $state = { content: "// ---- Reflected named types ----\n\n", seen: [] }
    var $type_id = 0
    for _entry in type_table.entries() {
        $state = emit_type_decl($state, type_table, duplicate_records, duplicate_tags, preferred_names, $type_id)
        $type_id = $type_id + 1
    }
    $state.content
}

emit_type_decl : { content : Str, seen : List(Str) }, TypeTable, List(Str), List(Str), TypeNamePlan.PreferredNames, U64 -> { content : Str, seen : List(Str) }
emit_type_decl = |state, type_table, duplicate_records, duplicate_tags, preferred_names, type_id| {
    type_info = type_table.type_info(type_id)
    match type_info.repr {
        RocRecord(rec) =>
            if rec.name == "" {
                state
            } else {
                name = record_struct_name(duplicate_records, type_id, rec)
                if List.contains(state.seen, name) {
                    state
                } else {
                    var $next = { content: state.content, seen: state.seen.append(name) }
                    for field in rec.fields {
                        if !field.is_padding {
                            $next = emit_type_decl($next, type_table, duplicate_records, duplicate_tags, preferred_names, field.type_id)
                        }
                    }
                    body = goose_record_body(type_table, duplicate_records, duplicate_tags, preferred_names, type_info.layout)
                    comment = "// record ${rec.name}  size64=${U64.to_str(type_info.layout.size64)} align64=${U64.to_str(type_info.layout.alignment64)}\n"
                    {
                        content: Str.concat($next.content, "${comment}struct ${name} {\n${body}}\n\n"),
                        seen: $next.seen,
                    }
                }
            }
        RocTagUnion(tu) =>
            match TypeTable.single_variant_payload(tu) {
                SinglePayload(payload_id) => emit_type_decl(state, type_table, duplicate_records, duplicate_tags, preferred_names, payload_id)
                SingleNoPayload => state
                NotSingleVariant =>
                    if tu.name == "" {
                        state
                    } else {
                        name = tag_union_struct_name(preferred_names, duplicate_tags, type_id, tu)
                        if List.contains(state.seen, name) {
                            state
                        } else {
                            var $next = { content: state.content, seen: state.seen.append(name) }
                            for tag in tu.tags {
                                for payload_id in tag.payload {
                                    $next = emit_type_decl($next, type_table, duplicate_records, duplicate_tags, preferred_names, payload_id)
                                }
                            }
                            decl = goose_tag_union_decl(preferred_names, duplicate_tags, type_id, tu, type_info.layout)
                            {
                                content: Str.concat($next.content, decl),
                                seen: $next.seen,
                            }
                        }
                    }
            }
        _ => state
    }
}

goose_record_body : TypeTable, List(Str), List(Str), TypeNamePlan.PreferredNames, AbiLayout -> Str
goose_record_body = |type_table, duplicate_records, duplicate_tags, preferred_names, layout| {
    abi_fields = abi_record_fields(layout)
    var $out = ""
    for field in abi_fields {
        $out = Str.concat($out, goose_field_line(type_table, duplicate_records, duplicate_tags, preferred_names, field, Pointer64))
    }
    $out
}

goose_field_line : TypeTable, List(Str), List(Str), TypeNamePlan.PreferredNames, AbiFieldLayout, AbiWidth -> Str
goose_field_line = |type_table, duplicate_records, duplicate_tags, preferred_names, field, width| {
    fname = name_to_field(field.name)
    if field.is_padding {
        n = AbiFieldLayout.size(field, width)
        if n == 0 {
            ""
        } else {
            "    // padding ${fname} (${U64.to_str(n)} bytes)\n    ${fname}: u8,\n"
        }
    } else {
        ty = type_id_to_goose(type_table, duplicate_records, duplicate_tags, preferred_names, field.type_id)
        "    ${fname}: ${ty},\n"
    }
}

goose_tag_union_decl : TypeNamePlan.PreferredNames, List(Str), U64, TagUnionRepr, AbiLayout -> Str
goose_tag_union_decl = |preferred_names, duplicate_tags, type_id, tu, layout| {
    name = tag_union_struct_name(preferred_names, duplicate_tags, type_id, tu)
    disc_size = layout.discriminant_size()
    disc_ty =
        if disc_size <= 1 {
            "u8"
        } else if disc_size == 2 {
            "u16"
        } else if disc_size == 4 {
            "u32"
        } else {
            "u64"
        }

    var $tag_docs = ""
    var $ti = 0
    for tag in tu.tags {
        $tag_docs = Str.concat($tag_docs, "//   ${U64.to_str($ti)} = ${tag.name}\n")
        $ti = $ti + 1
    }

    payload_bytes = layout.discriminant_offset(Pointer64)
    payload_u64s = (payload_bytes + 7) // 8

    var $payload_fields = ""
    var $i = 0
    while $i < payload_u64s {
        $payload_fields = Str.concat($payload_fields, "    p${U64.to_str($i)}: u64,\n")
        $i = $i + 1
    }

    comment =
        \\// tag-union ${tu.name}  size64=${U64.to_str(layout.size64)} align64=${U64.to_str(layout.alignment64)}
        \\// discriminant offset64=${U64.to_str(layout.discriminant_offset(Pointer64))}
        \\${$tag_docs}

    "${comment}struct ${name} {\n${$payload_fields}    tag: ${disc_ty},\n}\n\n"
}

# =============================================================================
# Hosted exports
# =============================================================================

generate_hosted_exports : List(HostedFunctionInfo), TypeTable, List(Str), List(Str), TypeNamePlan.PreferredNames -> Str
generate_hosted_exports = |hosted_functions, type_table, duplicate_records, duplicate_tags, preferred_names| {
    if List.is_empty(hosted_functions) {
        return "// (no hosted functions)\n"
    }

    var $out = "// ---- Hosted symbols (platform host must export) ----\n\n"
    arg_shape = ArgShape.from_table(type_table)

    for func in hosted_functions {
        params = goose_param_list(type_table, duplicate_records, duplicate_tags, preferred_names, arg_shape, func)
        ret = type_id_to_goose(type_table, duplicate_records, duplicate_tags, preferred_names, func.ret_type_id)
        snake = name_to_snake(func.name)
        doc =
            \\// Hosted: ${func.name}
            \\// Roc: ${func.type_str}
            \\// Symbol: ${func.ffi_symbol}
            \\
        stub =
            \\export "${func.ffi_symbol}" fn ${snake}(${params}) -> ${ret} {
            \\    abort("goose host: ${func.ffi_symbol} not implemented");
            \\}
            \\
            \\
        $out = Str.concat($out, doc)
        $out = Str.concat($out, stub)
    }
    $out
}

goose_param_list : TypeTable, List(Str), List(Str), TypeNamePlan.PreferredNames, ArgShape, HostedFunctionInfo -> Str
goose_param_list = |type_table, duplicate_records, duplicate_tags, preferred_names, arg_shape, func| {
    var $params = ""
    var $idx = 0
    for arg_type_id in arg_shape.positional_non_unit_type_ids(func.arg_type_ids) {
        ty = type_id_to_goose(type_table, duplicate_records, duplicate_tags, preferred_names, arg_type_id)
        sep = if $params == "" {
            ""
        } else {
            ", "
        }
        $params = "${$params}${sep}arg${U64.to_str($idx)}: ${ty}"
        $idx = $idx + 1
    }
    $params
}

# =============================================================================
# Provides
# =============================================================================

generate_provides_externs : List(ProvidesEntry), TypeTable, List(Str), List(Str), TypeNamePlan.PreferredNames -> Str
generate_provides_externs = |provides_list, type_table, duplicate_records, duplicate_tags, preferred_names| {
    if List.is_empty(provides_list) {
        return ""
    }

    var $out = "// ---- Provided by Roc app (host calls these) ----\n\n"
    for entry in provides_list {
        match entry.exported {
            ProvidedProcedure(func) => {
                var $params = ""
                var $idx = 0
                for arg_type_id in func.args {
                    ty = type_id_to_goose(type_table, duplicate_records, duplicate_tags, preferred_names, arg_type_id)
                    sep = if $params == "" {
                        ""
                    } else {
                        ", "
                    }
                    $params = "${$params}${sep}arg${U64.to_str($idx)}: ${ty}"
                    $idx = $idx + 1
                }
                ret = type_id_to_goose(type_table, duplicate_records, duplicate_tags, preferred_names, func.ret)
                $out = Str.concat(
                    $out,
                    "// provides ${entry.name}\nextern fn ${name_to_snake(entry.name)}(${$params}) -> ${ret};\n\n",
                )
            }
            ProvidedData(_) => {
                $out = Str.concat($out, "// provides data ${entry.name} (not emitted as Goose fn)\n")
            }
        }
    }
    $out
}
