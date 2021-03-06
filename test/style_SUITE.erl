-module(style_SUITE).

-export([
         all/0,
         init_per_suite/1,
         end_per_suite/1
        ]).

-export([
         verify_line_length_rule/1,
         verify_no_tabs_rule/1,
         verify_macro_names_rule/1,
         verify_macro_module_names/1,
         verify_operator_spaces/1,
         verify_nesting_level/1,
         verify_god_modules/1,
         verify_no_if_expression/1,
         verify_invalid_dynamic_call/1,
         verify_used_ignored_variable/1,
         verify_no_behavior_info/1,
         verify_module_naming_convention/1,
         verify_state_record_and_type/1,
         verify_no_spec_with_records/1
        ]).

-define(EXCLUDED_FUNS,
        [
         module_info,
         all,
         test,
         init_per_suite,
         end_per_suite
        ]).

-type config() :: [{atom(), term()}].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Common test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-spec all() -> [atom()].
all() ->
    Exports = ?MODULE:module_info(exports),
    [F || {F, _} <- Exports, not lists:member(F, ?EXCLUDED_FUNS)].

-spec init_per_suite(config()) -> config().
init_per_suite(Config) ->
    application:start(elvis),
    Config.

-spec end_per_suite(config()) -> config().
end_per_suite(Config) ->
    application:stop(elvis),
    Config.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Test Cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%
%%% Rules

-spec verify_line_length_rule(config()) -> any().
verify_line_length_rule(_Config) ->
    ElvisConfig = elvis_config:default(),
    SrcDirs = elvis_config:dirs(ElvisConfig),

    File = "fail_line_length.erl",
    {ok, Path} = elvis_test_utils:find_file(SrcDirs, File),

    [_, _, _, _, Utf] =
        elvis_style:line_length(ElvisConfig, Path, #{limit => 80}),

    #{info := Info, message := Msg} = Utf,
    <<"Line 29 is too long:     gb_trees:from_orddict(", _/binary>> =
        list_to_binary(io_lib:format(Msg, Info)).

-spec verify_no_tabs_rule(config()) -> any().
verify_no_tabs_rule(_Config) ->
    ElvisConfig = elvis_config:default(),
    SrcDirs = elvis_config:dirs(ElvisConfig),

    File = "fail_no_tabs.erl",
    {ok, Path} = elvis_test_utils:find_file(SrcDirs, File),

    [_, _] = elvis_style:no_tabs(ElvisConfig, Path, #{}).

-spec verify_macro_names_rule(config()) -> any().
verify_macro_names_rule(_Config) ->
    ElvisConfig = elvis_config:default(),
    SrcDirs = elvis_config:dirs(ElvisConfig),

    File = "fail_macro_names.erl",
    {ok, Path} = elvis_test_utils:find_file(SrcDirs, File),

    [_, _] = elvis_style:macro_names(ElvisConfig, Path, #{}).

-spec verify_macro_module_names(config()) -> any().
verify_macro_module_names(_Config) ->
    ElvisConfig = elvis_config:default(),
    SrcDirs = elvis_config:dirs(ElvisConfig),

    File = "fail_macro_module_names.erl",
    {ok, Path} = elvis_test_utils:find_file(SrcDirs, File),

    [_, _, _, _] = elvis_style:macro_module_names(ElvisConfig, Path, #{}).

-spec verify_operator_spaces(config()) -> any().
verify_operator_spaces(_Config) ->
    ElvisConfig = elvis_config:default(),
    SrcDirs = elvis_config:dirs(ElvisConfig),

    File = "fail_operator_spaces.erl",
    {ok, Path} = elvis_test_utils:find_file(SrcDirs, File),

    [] = elvis_style:operator_spaces(ElvisConfig, Path, #{}),

    RuleConfig = #{rules => [{right, ","}]},
    [_, _, _] = elvis_style:operator_spaces(ElvisConfig, Path, RuleConfig),

    AppendOptions = #{rules => [{right, "++"}, {left, "++"}]},
    [_] = elvis_style:operator_spaces(ElvisConfig, Path, AppendOptions),

    AllOptions = #{rules => [{right, ","}, {right, "++"}, {left, "++"}]},
    [_, _, _, _] = elvis_style:operator_spaces(ElvisConfig, Path, AllOptions).

-spec verify_nesting_level(config()) -> any().
verify_nesting_level(_Config) ->
    ElvisConfig = elvis_config:default(),
    SrcDirs = elvis_config:dirs(ElvisConfig),

    Path = "fail_nesting_level.erl",
    {ok, File} = elvis_test_utils:find_file(SrcDirs, Path),

    [
     #{line_num := 9},
     #{line_num := 16},
     #{line_num := 28},
     #{line_num := 43},
     #{line_num := 76},
     #{line_num := 118},
     #{line_num := 164}
    ] = elvis_style:nesting_level(ElvisConfig, File, #{limit => 3}).

-spec verify_god_modules(config()) -> any().
verify_god_modules(_Config) ->
    ElvisConfig = elvis_config:default(),
    SrcDirs = elvis_config:dirs(ElvisConfig),

    Path = "fail_god_modules.erl",
    {ok, File} = elvis_test_utils:find_file(SrcDirs, Path),

    [_] = elvis_style:god_modules(ElvisConfig, File, #{limit => 25}),

    RuleConfig = #{limit => 25, ignore => [fail_god_modules]},
    [] = elvis_style:god_modules(ElvisConfig, File, RuleConfig).

-spec verify_no_if_expression(config()) -> any().
verify_no_if_expression(_Config) ->
    ElvisConfig = elvis_config:default(),
    SrcDirs = elvis_config:dirs(ElvisConfig),

    Path = "fail_no_if_expression.erl",
    {ok, File} = elvis_test_utils:find_file(SrcDirs, Path),
    [
     #{line_num := 9},
     #{line_num := 20},
     #{line_num := 29}
    ] = elvis_style:no_if_expression(ElvisConfig, File, #{}).

-spec verify_invalid_dynamic_call(config()) -> any().
verify_invalid_dynamic_call(_Config) ->
    ElvisConfig = elvis_config:default(),
    SrcDirs = elvis_config:dirs(ElvisConfig),

    PathPass = "pass_invalid_dynamic_call.erl",
    {ok, FilePass} = elvis_test_utils:find_file(SrcDirs, PathPass),
    [] = elvis_style:invalid_dynamic_call(ElvisConfig, FilePass, #{}),

    PathFail = "fail_invalid_dynamic_call.erl",
    {ok, FileFail} = elvis_test_utils:find_file(SrcDirs, PathFail),
    [
     #{line_num := 13},
     #{line_num := 25},
     #{line_num := 26},
     #{line_num := 34}
    ] = elvis_style:invalid_dynamic_call(ElvisConfig, FileFail, #{}),

    RuleConfig = #{ignore => [fail_invalid_dynamic_call]},
    [] = elvis_style:invalid_dynamic_call(ElvisConfig,
                                          FileFail,
                                          RuleConfig).

-spec verify_used_ignored_variable(config()) -> any().
verify_used_ignored_variable(_Config) ->
    ElvisConfig = elvis_config:default(),
    SrcDirs = elvis_config:dirs(ElvisConfig),

    Path = "fail_used_ignored_variable.erl",
    {ok, File} = elvis_test_utils:find_file(SrcDirs, Path),
    [
     #{line_num := 10},
     #{line_num := 13},
     #{line_num := 17},
     #{line_num := 17}
    ] = elvis_style:used_ignored_variable(ElvisConfig, File, #{}).

-spec verify_no_behavior_info(config()) -> any().
verify_no_behavior_info(_Config) ->
    ElvisConfig = elvis_config:default(),
    SrcDirs = elvis_config:dirs(ElvisConfig),

    Path = "fail_no_behavior_info.erl",
    {ok, File} = elvis_test_utils:find_file(SrcDirs, Path),
    [
     #{line_num := 14},
     #{line_num := 17}
    ] = elvis_style:no_behavior_info(ElvisConfig, File, #{}).

-spec verify_module_naming_convention(config()) -> any().
verify_module_naming_convention(_Config) ->
    ElvisConfig = elvis_config:default(),
    SrcDirs = elvis_config:dirs(ElvisConfig),

    RuleConfig = #{regex => "^([a-z][a-z0-9]*_?)*$",
                   ignore => []},

    PathPass = "pass_module_naming_convention.erl",
    {ok, FilePass} = elvis_test_utils:find_file(SrcDirs, PathPass),
    [] =
        elvis_style:module_naming_convention(ElvisConfig, FilePass, RuleConfig),

    PathFail = "fail_module_naming_1_convention_1.erl",
    {ok, FileFail} = elvis_test_utils:find_file(SrcDirs, PathFail),
    [_] =
        elvis_style:module_naming_convention(ElvisConfig, FileFail, RuleConfig).

-spec verify_state_record_and_type(config()) -> any().
verify_state_record_and_type(_Config) ->
    ElvisConfig = elvis_config:default(),
    SrcDirs = elvis_config:dirs(ElvisConfig),

    PathPass = "pass_state_record_and_type.erl",
    {ok, FilePass} = elvis_test_utils:find_file(SrcDirs, PathPass),
    [] = elvis_style:state_record_and_type(ElvisConfig, FilePass, #{}),

    PathFail = "fail_state_record_and_type.erl",
    {ok, FileFail} = elvis_test_utils:find_file(SrcDirs, PathFail),
    [_] = elvis_style:state_record_and_type(ElvisConfig, FileFail, #{}),

    PathFail1 = "fail_state_type.erl",
    {ok, FileFail1} = elvis_test_utils:find_file(SrcDirs, PathFail1),
    [_] = elvis_style:state_record_and_type(ElvisConfig, FileFail1, #{}).

-spec verify_no_spec_with_records(config()) -> any().
verify_no_spec_with_records(_Config) ->
    ElvisConfig = elvis_config:default(),
    SrcDirs = elvis_config:dirs(ElvisConfig),

    PathFail = "fail_no_spec_with_records.erl",
    {ok, FileFail} = elvis_test_utils:find_file(SrcDirs, PathFail),
    [_, _, _] = elvis_style:no_spec_with_records(ElvisConfig, FileFail, #{}),

    PathPass = "pass_no_spec_with_records.erl",
    {ok, FilePass} = elvis_test_utils:find_file(SrcDirs, PathPass),
    [] = elvis_style:no_spec_with_records(ElvisConfig, FilePass, #{}).
