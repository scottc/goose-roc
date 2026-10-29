## A glue script for generating a Goose source file with hosted function bindings.
app [make_glue] { pf: platform glue }

import pf.Types exposing [Types]
import pf.File exposing [File]
import pf.RecordFieldInfo exposing [RecordFieldInfo]
import pf.TypeRepr exposing [TypeRepr]
import pf.AbiLayout exposing [AbiLayout]
import pf.AbiFieldLayout exposing [AbiFieldLayout]
import pf.AbiTagLayout exposing [AbiTagLayout]
import pf.AbiWidth exposing [AbiWidth]
import pf.ArgShape exposing [ArgShape]
import pf.GlueInput exposing [GlueInput]
import pf.HostedFunctionInfo exposing [HostedFunctionInfo]
import pf.TypeNamePlan exposing [TypeNamePlan]
import pf.RecordRepr exposing [RecordRepr]
import pf.TagUnionRepr exposing [TagUnionRepr]
import pf.RecordField exposing [RecordField]
import pf.TagVariant exposing [TagVariant]
import pf.ProvidesEntry exposing [ProvidesEntry]
import pf.TypeInfo exposing [TypeInfo]
import pf.TypeTable exposing [TypeTable]
import pf.RocName exposing [RocName]

make_glue : List(Types) -> Try(List(File), Str)
make_glue = |types_list| {
	input = GlueInput.from_types(types_list)
	type_table = TypeTable.from_list(input.types)
	goose_content = generate_goose_file(input.hosted_functions, type_table, input.provides_entries)

	Ok([{ name: "roc_platform_abi.zig", content: goose_content }])
}

generate_goose_file = |a, b, c| {

}
