grammar SQL2011;


// 5 Lexical elements

// 5.1     <SQL terminal character>

fragment
SIMPLE_LATIN_LETTER
    : SIMPLE_LATIN_UPPER_CASE_LETTER
    | SIMPLE_LATIN_LOWER_CASE_LETTER
    ;

fragment
SIMPLE_LATIN_UPPER_CASE_LETTER
    : 'A'
    | 'B'
    | 'C'
    | 'D'
    | 'E'
    | 'F'
    | 'G'
    | 'H'
    | 'I'
    | 'J'
    | 'K'
    | 'L'
    | 'M'
    | 'N'
    | 'O'
    | 'P'
    | 'Q'
    | 'R'
    | 'S'
    | 'T'
    | 'U'
    | 'V'
    | 'W'
    | 'X'
    | 'Y'
    | 'Z'
    ;

fragment
SIMPLE_LATIN_LOWER_CASE_LETTER
    : 'a'
    | 'b'
    | 'c'
    | 'd'
    | 'e'
    | 'f'
    | 'g'
    | 'h'
    | 'i'
    | 'j'
    | 'k'
    | 'l'
    | 'm'
    | 'n'
    | 'o'
    | 'p'
    | 'q'
    | 'r'
    | 's'
    | 't'
    | 'u'
    | 'v'
    | 'w'
    | 'x'
    | 'y'
    | 'z'
    ;

fragment
DIGIT
    : '0'
    | '1'
    | '2'
    | '3'
    | '4'
    | '5'
    | '6'
    | '7'
    | '8'
    | '9'
    ;

fragment
SPACE
    : ' '
    ;

DOUBLE_QUOTE
    : '"'
    ;

PERCENT
    : '%'
    ;

AMPERSAND
    : '&'
    ;

QUOTE
    : '\''
    ;

LEFT_PAREN
    : '('
    ;

RIGHT_PAREN
    : ')'
    ;

ASTERISK
    : '*'
    ;

PLUS_SIGN
    : '+'
    ;

COMMA
    : ','
    ;

MINUS_SIGN
    : '-'
    ;

PERIOD
    : '.'
    ;

SOLIDUS
    : '/'
    ;

REVERSE_SOLIDUS
    : '\\'
    ;

COLON
    : ':'
    ;

SEMICOLON
    : ';'
    ;

LESS_THAN_OPERATOR
    : '<'
    ;

EQUALS_OPERATOR
    : '='
    ;

GREATER_THAN_OPERATOR
    : '>'
    ;

QUESTION_MARK
    : '?'
    ;

LEFT_BRACKET_OR_TRIGRAPH
    : LEFT_BRACKET
    | LEFT_BRACKET_TRIGRAPH
    ;

RIGHT_BRACKET_OR_TRIGRAPH
    : RIGHT_BRACKET
    | RIGHT_BRACKET_TRIGRAPH
    ;

LEFT_BRACKET
    : '['
    ;

LEFT_BRACKET_TRIGRAPH
    : '??('
    ;

RIGHT_BRACKET
    : ']'
    ;

RIGHT_BRACKET_TRIGRAPH
    : '??)'
    ;

CIRCUMFLEX
    : '^'
    ;

UNDERSCORE
    : '_'
    ;

VERTICAL_BAR
    : '|'
    ;

LEFT_BRACE
    : '{'
    ;

RIGHT_BRACE
    : '}'
    ;

// 5.2     <token> and <separator>

regular_identifier
    : IDENTIFIER_BODY
    ;

IDENTIFIER_BODY
    : IDENTIFIER_START IDENTIFIER_PART*
    ;

fragment
IDENTIFIER_PART
    : IDENTIFIER_START
    | IDENTIFIER_EXTEND
    ;

fragment
IDENTIFIER_START
    : SIMPLE_LATIN_LETTER
    ;

fragment
IDENTIFIER_EXTEND
    : SIMPLE_LATIN_LETTER
    | DIGIT
    | UNDERSCORE
    ;

LARGE_OBJECT_LENGTH_TOKEN
    : DIGIT+ MULTIPLIER
    ;

MULTIPLIER
    : 'K'
    | 'M'
    | 'G'
    | 'T'
    | 'P'
    ;

DELIMITED_IDENTIFIER
    : DOUBLE_QUOTE DELIMITED_IDENTIFIER_BODY DOUBLE_QUOTE
    ;

fragment
DELIMITED_IDENTIFIER_BODY
    : DELIMITED_IDENTIFIER_PART+
    ;

fragment
DELIMITED_IDENTIFIER_PART
    : NONDOUBLEQUOTE_CHARACTER
    | DOUBLEQUOTE_SYMBOL
    ;

UNICODE_DELIMITED_IDENTIFIER
    : 'U' AMPERSAND DOUBLE_QUOTE UNICODE_DELIMITER_BODY DOUBLE_QUOTE UNICODE_ESCAPE_SPECIFIER
    ;

fragment
UNICODE_ESCAPE_SPECIFIER
    : ('UESCAPE' QUOTE UNICODE_ESCAPE_CHARACTER QUOTE)?
    ;

fragment
UNICODE_DELIMITER_BODY
    : UNICODE_IDENTIFIER_PART+
    ;

fragment
UNICODE_IDENTIFIER_PART
    : DELIMITED_IDENTIFIER_PART
    | UNICODE_ESCAPE_VALUE
    ;

fragment
UNICODE_ESCAPE_VALUE
    : UNICODE_4_DIGIT_ESCAPE_VALUE
    | UNICODE_6_DIGIT_ESCAPE_VALUE
    | UNICODE_CHARACTER_ESCAPE_VALUE
    ;

fragment
UNICODE_4_DIGIT_ESCAPE_VALUE
    : UNICODE_ESCAPE_CHARACTER HEXIT HEXIT HEXIT HEXIT
    ;

fragment
UNICODE_6_DIGIT_ESCAPE_VALUE
    : UNICODE_ESCAPE_CHARACTER PLUS_SIGN HEXIT HEXIT HEXIT HEXIT HEXIT HEXIT
    ;

fragment
UNICODE_CHARACTER_ESCAPE_VALUE
    : UNICODE_ESCAPE_CHARACTER UNICODE_ESCAPE_CHARACTER
    ;

fragment
UNICODE_ESCAPE_CHARACTER
    : '\\'
    ;

fragment
NONDOUBLEQUOTE_CHARACTER
    : ~'"'
    ;

fragment
DOUBLEQUOTE_SYMBOL
    : '""'
    ;

NOT_EQUALS_OPERATOR
    : '<>'
    ;

GREATER_THAN_OR_EQUALS_OPERATOR
    : '>='
    ;

LESS_THAN_OR_EQUALS_OPERATOR
    : '<='
    ;

CONCATENATION_OPERATOR
    : '||'
    ;

RIGHT_ARROW
    : '->'
    ;

DOUBLE_COLON
    : '::'
    ;

DOUBLE_PERIOD
    : '..'
    ;

NAMED_ARGUMENT_ASSIGNMENT_TOKEN
    : '=>'
    ;

SEPARATOR
    : (COMMENT | WHITE_SPACE)+ -> skip
    ;

WHITE_SPACE
    : [\n\r\t ]+ -> skip
    ;

COMMENT
    : (SIMPLE_COMMENT | BRACKETED_COMMENT) -> skip
    ;

fragment
SIMPLE_COMMENT
    : SIMPLE_COMMENT_INTRODUCER COMMENT_CHARACTER* NEWLINE
    ;

fragment
SIMPLE_COMMENT_INTRODUCER
    : MINUS_SIGN MINUS_SIGN
    ;

fragment
BRACKETED_COMMENT
    : BRACKETED_COMMENT_INTRODUCER BRACKETED_COMMENT_CONTENTS BRACKETED_COMMENT_TERMINATOR
    ;

fragment
BRACKETED_COMMENT_INTRODUCER
    : '/*'
    ;

fragment
BRACKETED_COMMENT_TERMINATOR
    : '*/'
    ;

fragment
BRACKETED_COMMENT_CONTENTS
    : (COMMENT_CHARACTER | SEPARATOR)* .
    ;

fragment
COMMENT_CHARACTER
    : NONQUOTE_CHARACTER
    | QUOTE
    ;

fragment
NEWLINE
    : [\r\n]+
    ;

// 5.3     <literal>

literal
    : signed_numeric_literal
    | general_literal
    ;

unsigned_literal
    : unsigned_numeric_literal
    | general_literal
    ;

general_literal
    : CHARACTER_STRING_LITERAL
    | UNICODE_CHARACTER_STRING_LITERAL
    | BINARY_STRING_LITERAL
    | datetime_literal
    | INTERVAL_LITERAL
    | BOOLEAN_LITERAL
    ;

CHARACTER_STRING_LITERAL
    : QUOTE CHARACTER_REPRESENTATION* QUOTE (SEPARATOR QUOTE CHARACTER_REPRESENTATION* QUOTE)*
    ;

fragment
CHARACTER_REPRESENTATION
    : NONQUOTE_CHARACTER
    | QUOTE_SYMBOL
    ;

fragment
NONQUOTE_CHARACTER
    : ~'\''
    ;

fragment
QUOTE_SYMBOL
    : QUOTE QUOTE
    ;

UNICODE_CHARACTER_STRING_LITERAL
    : 'U' AMPERSAND QUOTE UNICODE_REPRESENTATION* QUOTE (SEPARATOR QUOTE UNICODE_REPRESENTATION* QUOTE)* UNICODE_ESCAPE_SPECIFIER
    ;

fragment
UNICODE_REPRESENTATION
    : CHARACTER_REPRESENTATION
    | UNICODE_ESCAPE_VALUE
    ;

BINARY_STRING_LITERAL
    : 'X' QUOTE SPACE* (HEXIT SPACE* HEXIT SPACE*)* QUOTE (SEPARATOR QUOTE SPACE* (HEXIT SPACE* HEXIT SPACE*)* QUOTE)*
    ;

fragment
HEXIT
    : DIGIT
    | 'A'
    | 'B'
    | 'C'
    | 'D'
    | 'E'
    | 'F'
    | 'a'
    | 'b'
    | 'c'
    | 'd'
    | 'e'
    | 'f'
    ;

signed_numeric_literal
    : sign? unsigned_numeric_literal
    ;

unsigned_numeric_literal
    : EXACT_NUMERIC_LITERAL
    | APPROXIMATE_NUMERIC_LITERAL
    ;

EXACT_NUMERIC_LITERAL
    : UNSIGNED_INTEGER (PERIOD UNSIGNED_INTEGER?)?
    | PERIOD UNSIGNED_INTEGER
    ;

sign
    : PLUS_SIGN
    | MINUS_SIGN
    ;

APPROXIMATE_NUMERIC_LITERAL
    : MANTISSA 'E' EXPONENT
    ;

fragment
MANTISSA
    : EXACT_NUMERIC_LITERAL
    ;

fragment
EXPONENT
    : SIGNED_INTEGER
    ;

fragment
SIGNED_INTEGER
    : (PLUS_SIGN | MINUS_SIGN)? UNSIGNED_INTEGER
    ;

UNSIGNED_INTEGER
    : DIGIT+
    ;

datetime_literal
    : DATE_LITERAL
    | TIME_LITERAL
    | TIMESTAMP_LITERAL
    ;

DATE_LITERAL
    : 'DATE' SPACE* DATE_STRING
    ;

TIME_LITERAL
    : 'TIME' SPACE* TIME_STRING
    ;

TIMESTAMP_LITERAL
    : 'TIMESTAMP' SPACE* TIMESTAMP_STRING
    ;

fragment
DATE_STRING
    : QUOTE UNQUOTED_DATE_STRING QUOTE
    ;

fragment
TIME_STRING
    : QUOTE UNQUOTED_TIME_STRING QUOTE
    ;

fragment
TIMESTAMP_STRING
    : QUOTE UNQUOTED_TIMESTAMP_STRING QUOTE
    ;

fragment
TIME_ZONE_INTERVAL
    : (PLUS_SIGN | MINUS_SIGN) HOURS_VALUE COLON MINUTES_VALUE
    ;

fragment
DATE_VALUE
    : YEARS_VALUE MINUS_SIGN MONTHS_VALUE MINUS_SIGN DAYS_VALUE
    ;

fragment
TIME_VALUE
    : HOURS_VALUE COLON MINUTES_VALUE COLON SECONDS_VALUE
    ;

INTERVAL_LITERAL
    : 'INTERVAL' SPACE* (PLUS_SIGN | MINUS_SIGN)? SPACE* INTERVAL_STRING SPACE* INTERVAL_QUALIFIER
    ;

fragment
INTERVAL_STRING
    : QUOTE UNQUOTED_INTERVAL_STRING QUOTE
    ;

fragment
UNQUOTED_DATE_STRING
    : DATE_VALUE
    ;

fragment
UNQUOTED_TIME_STRING
    : TIME_VALUE TIME_ZONE_INTERVAL?
    ;

fragment
UNQUOTED_TIMESTAMP_STRING
    : UNQUOTED_DATE_STRING SPACE UNQUOTED_TIME_STRING
    ;

fragment
UNQUOTED_INTERVAL_STRING
    : (PLUS_SIGN | MINUS_SIGN)? (YEAR_MONTH_LITERAL | DAY_TIME_LITERAL)
    ;

fragment
YEAR_MONTH_LITERAL
    : YEARS_VALUE (MINUS_SIGN MONTHS_VALUE)?
    | MONTHS_VALUE
    ;

fragment
DAY_TIME_LITERAL
    : DAY_TIME_INTERVAL
    | TIME_INTERVAL
    ;

fragment
DAY_TIME_INTERVAL
    : DAYS_VALUE (SPACE HOURS_VALUE (COLON MINUTES_VALUE (COLON SECONDS_VALUE)?)?)?
    ;

fragment
TIME_INTERVAL
    : HOURS_VALUE (COLON MINUTES_VALUE (COLON SECONDS_VALUE)?)?
    | MINUTES_VALUE (COLON SECONDS_VALUE)?
    | SECONDS_VALUE
    ;

fragment
YEARS_VALUE
    : DATETIME_VALUE
    ;

fragment
MONTHS_VALUE
    : DATETIME_VALUE
    ;

fragment
DAYS_VALUE
    : DATETIME_VALUE
    ;

fragment
HOURS_VALUE
    : DATETIME_VALUE
    ;

fragment
MINUTES_VALUE
    : DATETIME_VALUE
    ;

fragment
SECONDS_VALUE
    : SECONDS_INTEGER_VALUE (PERIOD SECONDS_FRACTION?)?
    ;

fragment
SECONDS_INTEGER_VALUE
    : UNSIGNED_INTEGER
    ;

fragment
SECONDS_FRACTION
    : UNSIGNED_INTEGER
    ;

fragment
DATETIME_VALUE
    : UNSIGNED_INTEGER
    ;

BOOLEAN_LITERAL
    : 'TRUE'
    | 'FALSE'
    | 'UNKNOWN'
    ;

// 5.4    Names and identifiers

identifier
    : actual_identifier
    ;

actual_identifier
    : regular_identifier
    | DELIMITED_IDENTIFIER
    | UNICODE_DELIMITED_IDENTIFIER
    ;

authorization_identifier
    : role_name
    | user_identifier
    ;

table_name
    : local_or_schema_qualified_name
    ;

domain_name
    : schema_qualified_name
    ;

schema_name
    : (catalog_name PERIOD)? unqualified_schema_name
    ;

unqualified_schema_name
    : identifier
    ;

catalog_name
    : identifier
    ;

schema_qualified_name
    : (schema_name PERIOD)? qualified_identifier
    ;

local_or_schema_qualified_name
    : (local_or_schema_qualifier PERIOD)? qualified_identifier
    ;

local_or_schema_qualifier
    : schema_name
    | local_qualifier
    ;

qualified_identifier
    : identifier
    ;

column_name
    : identifier
    ;

correlation_name
    : identifier
    ;

query_name
    : identifier
    ;

sql_client_module_name
    : identifier
    ;

procedure_name
    : identifier
    ;

schema_qualified_routine_name
    : schema_qualified_name
    ;

method_name
    : identifier
    ;

specific_name
    : schema_qualified_name
    ;

cursor_name
    : local_qualified_name
    ;

local_qualified_name
    : (local_qualifier PERIOD)? qualified_identifier
    ;

local_qualifier
    : 'MODULE'
    ;

host_parameter_name
    : COLON identifier
    ;

sql_parameter_name
    : identifier
    ;

constraint_name
    : schema_qualified_name
    ;

external_routine_name
    : identifier
    | CHARACTER_STRING_LITERAL
    ;

trigger_name
    : schema_qualified_name
    ;

collation_name
    : schema_qualified_name
    ;

character_set_name
    : (schema_name PERIOD)? identifier
    ;

transliteration_name
    : schema_qualified_name
    ;

transcoding_name
    : schema_qualified_name
    ;

schema_resolved_user_defined_type_name
    : user_defined_type_name
    ;

user_defined_type_name
    : (schema_name PERIOD)? qualified_identifier
    ;

attribute_name
    : identifier
    ;

field_name
    : identifier
    ;

savepoint_name
    : identifier
    ;

sequence_generator_name
    : schema_qualified_name
    ;

role_name
    : identifier
    ;

user_identifier
    : identifier
    ;

connection_name
    : simple_value_specification
    ;

sql_server_name
    : simple_value_specification
    ;

connection_user_name
    : simple_value_specification
    ;

sql_statement_name
    : statement_name
    | extended_statement_name
    ;

statement_name
    : identifier
    ;

extended_statement_name
    : scope_option? simple_value_specification
    ;

dynamic_cursor_name
    : cursor_name
    | extended_cursor_name
    ;

extended_cursor_name
    : scope_option? simple_value_specification
    ;

descriptor_name
    : non_extended_descriptor_name
    | extended_descriptor_name
    ;

non_extended_descriptor_name
    : identifier
    ;

extended_descriptor_name
    : scope_option? simple_value_specification
    ;

scope_option
    : 'GLOBAL'
    | 'LOCAL'
    ;

window_name
    : identifier
    ;

// 6 Scalar expressions

// 6.1     <data type>

data_type
    : predefined_type
    | row_type
    | path_resolved_user_defined_type_name
    | reference_type
    | data_type 'ARRAY' (LEFT_BRACKET_OR_TRIGRAPH maximum_cardinality RIGHT_BRACKET_OR_TRIGRAPH)?
    | data_type 'MULTISET'
    ;

predefined_type
    : character_string_type ('CHARACTER' 'SET' character_set_specification)? collate_clause?
    | binary_string_type
    | numeric_type
    | boolean_type
    | datetime_type
    | interval_type
    ;

character_string_type
    : 'CHARACTER' (LEFT_PAREN character_length RIGHT_PAREN)?
    | 'CHAR' (LEFT_PAREN character_length RIGHT_PAREN)?
    | 'CHARACTER' 'VARYING' LEFT_PAREN character_length RIGHT_PAREN
    | 'CHAR' 'VARYING' LEFT_PAREN character_length RIGHT_PAREN
    | 'VARCHAR' LEFT_PAREN character_length RIGHT_PAREN
    | character_large_object_type
    ;

character_large_object_type
    : 'CHARACTER' 'LARGE' 'OBJECT' (LEFT_PAREN character_large_object_length RIGHT_PAREN)?
    | 'CHAR' 'LARGE' 'OBJECT' (LEFT_PAREN character_large_object_length RIGHT_PAREN)?
    | 'CLOB' (LEFT_PAREN character_large_object_length RIGHT_PAREN)?
    ;

binary_string_type
    : 'BINARY' (LEFT_PAREN length RIGHT_PAREN)?
    | 'BINARY' 'VARYING' LEFT_PAREN length RIGHT_PAREN
    | 'VARBINARY' LEFT_PAREN length RIGHT_PAREN
    | binary_large_object_string_type
    ;

binary_large_object_string_type
    : 'BINARY' 'LARGE' 'OBJECT' (LEFT_PAREN large_object_length RIGHT_PAREN)?
    | 'BLOB' (LEFT_PAREN large_object_length RIGHT_PAREN)?
    ;

numeric_type
    : exact_numeric_type
    | approximate_numeric_type
    ;

exact_numeric_type
    : 'NUMERIC' (LEFT_PAREN precision (COMMA scale)? RIGHT_PAREN)?
    | 'DECIMAL' (LEFT_PAREN precision (COMMA scale)? RIGHT_PAREN)?
    | 'DEC' (LEFT_PAREN precision (COMMA scale)? RIGHT_PAREN)?
    | 'SMALLINT'
    | 'INTEGER'
    | 'INT'
    | 'BIGINT'
    ;

approximate_numeric_type
    : 'FLOAT' (LEFT_PAREN precision RIGHT_PAREN)?
    | 'REAL'
    | 'DOUBLE' 'PRECISION'
    ;

length
    : UNSIGNED_INTEGER
    ;

character_length
    : length char_length_units?
    ;

large_object_length
    : length MULTIPLIER?
    | LARGE_OBJECT_LENGTH_TOKEN
    ;

character_large_object_length
    : large_object_length char_length_units?
    ;

char_length_units
    : 'CHARACTERS'
    | 'OCTETS'
    ;

precision
    : UNSIGNED_INTEGER
    ;

scale
    : UNSIGNED_INTEGER
    ;

boolean_type
    : 'BOOLEAN'
    ;

datetime_type
    : 'DATE'
    | 'TIME' (LEFT_PAREN time_precision RIGHT_PAREN)? with_or_without_time_zone?
    | 'TIMESTAMP' (LEFT_PAREN timestamp_precision RIGHT_PAREN)? with_or_without_time_zone?
    ;

with_or_without_time_zone
    : 'WITH' 'TIME' 'ZONE'
    | 'WITHOUT' 'TIME' 'ZONE'
    ;

time_precision
    : time_fractional_seconds_precision
    ;

timestamp_precision
    : time_fractional_seconds_precision
    ;

time_fractional_seconds_precision
    : UNSIGNED_INTEGER
    ;

interval_type
    : 'INTERVAL' INTERVAL_QUALIFIER
    ;

row_type
    : 'ROW' row_type_body
    ;

row_type_body
    : LEFT_PAREN field_definition (COMMA field_definition)* RIGHT_PAREN
    ;

reference_type
    : 'REF' LEFT_PAREN referenced_type RIGHT_PAREN scope_clause?
    ;

scope_clause
    : 'SCOPE' table_name
    ;

referenced_type
    : path_resolved_user_defined_type_name
    ;

path_resolved_user_defined_type_name
    : user_defined_type_name
    ;

maximum_cardinality
    : UNSIGNED_INTEGER
    ;

// 6.2        <field definition>

field_definition
    : field_name data_type
    ;

// 6.3         <value expression primary>

value_expression_primary
    : parenthesized_value_expression
    | unsigned_value_specification
    | column_reference
    | set_function_specification
    | window_function
    | nested_window_function
    | scalar_subquery
    | case_expression
    | cast_specification
    | value_expression_primary PERIOD field_name
    | subtype_treatment
    | value_expression_primary PERIOD method_name sql_argument_list?
    | generalized_invocation
    | static_method_invocation
    | new_specification
    | value_expression_primary dereference_operator qualified_identifier sql_argument_list?
    | reference_resolution
    | collection_value_constructor
    | value_expression_primary CONCATENATION_OPERATOR array_primary LEFT_BRACKET_OR_TRIGRAPH numeric_value_expression RIGHT_BRACKET_OR_TRIGRAPH
    | array_value_function LEFT_BRACKET_OR_TRIGRAPH numeric_value_expression RIGHT_BRACKET_OR_TRIGRAPH
    | value_expression_primary LEFT_BRACKET_OR_TRIGRAPH numeric_value_expression RIGHT_BRACKET_OR_TRIGRAPH
    | multiset_element_reference
    | next_value_expression
    | routine_invocation
    ;

parenthesized_value_expression
    : LEFT_PAREN value_expression RIGHT_PAREN
    ;

collection_value_constructor
    : array_value_constructor
    | multiset_value_constructor
    ;

// 6.4     <value specification> and <target specification>

value_specification
    : literal
    | general_value_specification
    ;

unsigned_value_specification
    : unsigned_literal
    | general_value_specification
    ;

general_value_specification
    : host_parameter_specification
    | sql_parameter_reference
    | dynamic_parameter_specification
    | embedded_variable_specification
    | current_collation_specification
    | 'CURRENT_CATALOG'
    | 'CURRENT_DEFAULT_TRANSFORM_GROUP'
    | 'CURRENT_PATH'
    | 'CURRENT_ROLE'
    | 'CURRENT_SCHEMA'
    | 'CURRENT_TRANSFORM_GROUP_FOR_TYPE' path_resolved_user_defined_type_name
    | 'CURRENT_USER'
    | 'SESSION_USER'
    | 'SYSTEM_USER'
    | 'USER'
    | 'VALUE'
    ;

simple_value_specification
    : literal
    | host_parameter_name
    | sql_parameter_reference
    | embedded_variable_name
    ;

target_specification
    : host_parameter_specification
    | sql_parameter_reference
    | column_reference
    | target_array_element_specification
    | dynamic_parameter_specification
    | embedded_variable_specification
    ;

simple_target_specification
    : host_parameter_name
    | sql_parameter_reference
    | column_reference
    | embedded_variable_name
    ;

host_parameter_specification
    : host_parameter_name indicator_parameter?
    ;

dynamic_parameter_specification
    : QUESTION_MARK
    ;

embedded_variable_specification
    : embedded_variable_name indicator_variable?
    ;

indicator_variable
    : 'INDICATOR'? embedded_variable_name
    ;

indicator_parameter
    : 'INDICATOR'? host_parameter_name
    ;

target_array_element_specification
    : target_array_reference LEFT_BRACKET_OR_TRIGRAPH simple_value_specification RIGHT_BRACKET_OR_TRIGRAPH
    ;

target_array_reference
    : sql_parameter_reference
    | column_reference
    ;

current_collation_specification
    : 'COLLATION' 'FOR' LEFT_PAREN string_value_expression RIGHT_PAREN
    ;

// 6.5        <contextually typed value specification>

contextually_typed_value_specification
    : implicitly_typed_value_specification
    | default_specification
    ;

implicitly_typed_value_specification
    : null_specification
    | empty_specification
    ;

null_specification
    : 'NULL'
    ;

empty_specification
    : 'ARRAY' LEFT_BRACKET_OR_TRIGRAPH RIGHT_BRACKET_OR_TRIGRAPH
    | 'MULTISET' LEFT_BRACKET_OR_TRIGRAPH RIGHT_BRACKET_OR_TRIGRAPH
    ;

default_specification
    : 'DEFAULT'
    ;

// 6.6        <identifier chain>

identifier_chain
    : identifier (PERIOD identifier)*
    ;

basic_identifier_chain
    : identifier_chain
    ;

// 6.7        <column reference>

column_reference
    : basic_identifier_chain
    | 'MODULE' PERIOD qualified_identifier PERIOD column_name
    ;

// 6.8      <SQL parameter reference>

sql_parameter_reference
    : basic_identifier_chain
    ;

// 6.9        <set function specification>

set_function_specification
    : aggregate_function
    | grouping_operation
    ;

grouping_operation
    : 'GROUPING' LEFT_PAREN column_reference (COMMA column_reference)* RIGHT_PAREN
    ;

// 6.10 <window function>

window_function
    : window_function_type 'OVER' window_name_or_specification
    ;

window_function_type
    : rank_function_type LEFT_PAREN RIGHT_PAREN
    | 'ROW_NUMBER' LEFT_PAREN RIGHT_PAREN
    | aggregate_function
    | ntile_function
    | lead_or_lag_function
    | first_or_last_value_function
    | nth_value_function
    ;

rank_function_type
    : 'RANK'
    | 'DENSE_RANK'
    | 'PERCENT_RANK'
    | 'CUME_DIST'
    ;

ntile_function
    : 'NTILE' LEFT_PAREN number_of_tiles RIGHT_PAREN
    ;

number_of_tiles
    : simple_value_specification
    | dynamic_parameter_specification
    ;

lead_or_lag_function
    : lead_or_lag LEFT_PAREN lead_or_lag_extent (COMMA offset (COMMA default_expression)?)? RIGHT_PAREN null_treatment?
    ;

lead_or_lag
    : 'LEAD'
    | 'LAG'
    ;

lead_or_lag_extent
    : value_expression
    ;

offset
    : EXACT_NUMERIC_LITERAL
    ;

default_expression
    : value_expression
    ;

null_treatment
    : 'RESPECT' 'NULLS'
    | 'IGNORE' 'NULLS'
    ;

first_or_last_value_function
    : first_or_last_value LEFT_PAREN value_expression RIGHT_PAREN null_treatment?
    ;

first_or_last_value
    : 'FIRST_VALUE'
    | 'LAST_VALUE'
    ;

nth_value_function
    : 'NTH_VALUE' LEFT_PAREN value_expression COMMA nth_row RIGHT_PAREN from_first_or_last? null_treatment?
    ;

nth_row
    : simple_value_specification
    | dynamic_parameter_specification
    ;

from_first_or_last
    : 'FROM' 'FIRST'
    | 'FROM' 'LAST'
    ;

window_name_or_specification
    : window_name
    | in_line_window_specification
    ;

in_line_window_specification
    : window_specification
    ;

// 6.11 <nested window function>

nested_window_function
    : nested_row_number_function
    | value_of_expression_at_row
    ;

nested_row_number_function
    : 'ROW_NUMBER' LEFT_PAREN row_marker RIGHT_PAREN
    ;

value_of_expression_at_row
    : 'VALUE_OF' LEFT_PAREN value_expression 'AT' row_marker_expression (COMMA value_of_default_value)? RIGHT_PAREN
    ;

row_marker
    : 'BEGIN_PARTITION'
    | 'BEGIN_FRAME'
    | 'CURRENT_ROW'
    | 'FRAME_ROW'
    | 'END_FRAME'
    | 'END_PARTITION'
    ;

row_marker_expression
    : row_marker row_marker_delta?
    ;

row_marker_delta
    : PLUS_SIGN row_marker_offset
    | MINUS_SIGN row_marker_offset
    ;

row_marker_offset
    : simple_value_specification
    | dynamic_parameter_specification
    ;

value_of_default_value
    : value_expression
    ;

// 6.12 <case expression>

case_expression
    : case_abbreviation
    | case_specification
    ;

case_abbreviation
    : 'NULLIF' LEFT_PAREN value_expression COMMA value_expression RIGHT_PAREN
    | 'COALESCE' LEFT_PAREN value_expression (COMMA value_expression)+ RIGHT_PAREN
    ;

case_specification
    : simple_case
    | searched_case
    ;

simple_case
    : 'CASE' case_operand simple_when_clause+ else_clause? 'END'
    ;

searched_case
    : 'CASE' searched_when_clause+ else_clause? 'END'
    ;

simple_when_clause
    : 'WHEN' when_operand_list 'THEN' result
    ;

searched_when_clause
    : 'WHEN' search_condition 'THEN' result
    ;

else_clause
    : 'ELSE' result
    ;

case_operand
    : row_value_predicand
    | overlaps_predicate_part_1
    ;

when_operand_list
    : when_operand (COMMA when_operand)*
    ;

when_operand
    : row_value_predicand
    | comparison_predicate_part_2
    | between_predicate_part_2
    | in_predicate_part_2
    | character_like_predicate_part_2
    | octet_like_predicate_part_2
    | similar_predicate_part_2
    | regex_like_predicate_part_2
    | null_predicate_part_2
    | quantified_comparison_predicate_part_2
    | normalized_predicate_part_2
    | match_predicate_part_2
    | overlaps_predicate_part_2
    | distinct_predicate_part_2
    | member_predicate_part_2
    | submultiset_predicate_part_2
    | set_predicate_part_2
    | type_predicate_part_2
    ;

result
    : result_expression
    | 'NULL'
    ;

result_expression
    : value_expression
    ;

// 6.13 <cast specification>

cast_specification
    : 'CAST' LEFT_PAREN cast_operand 'AS' cast_target RIGHT_PAREN
    ;

cast_operand
    : value_expression
    | implicitly_typed_value_specification
    ;

cast_target
    : domain_name
    | data_type
    ;

// 6.14 <next value expression>

next_value_expression
    : 'NEXT' 'VALUE' 'FOR' sequence_generator_name
    ;

// 6.15 <field reference>

// 6.16 <subtype treatment>

subtype_treatment
    : 'TREAT' LEFT_PAREN subtype_operand 'AS' target_subtype RIGHT_PAREN
    ;

subtype_operand
    : value_expression
    ;

target_subtype
    : path_resolved_user_defined_type_name
    | reference_type
    ;

// 6.17 <method invocation>

method_invocation
    : direct_invocation
    | generalized_invocation
    ;

direct_invocation
    : value_expression_primary PERIOD method_name sql_argument_list?
    ;

generalized_invocation
    : LEFT_PAREN value_expression_primary 'AS' data_type RIGHT_PAREN PERIOD method_name sql_argument_list?
    ;

method_selection
    : routine_invocation
    ;

constructor_method_selection
    : routine_invocation
    ;

// 6.18 <static method invocation>

static_method_invocation
    : path_resolved_user_defined_type_name DOUBLE_COLON method_name sql_argument_list?
    ;

static_method_selection
    : routine_invocation
    ;

// 6.19 <new specification>

new_specification
    : 'NEW' path_resolved_user_defined_type_name sql_argument_list
    ;

new_invocation
    : method_invocation
    | routine_invocation
    ;

// 6.20 <attribute or method reference>

dereference_operator
    : RIGHT_ARROW
    ;

// 6.21 <dereference operation>

dereference_operation
    : reference_value_expression dereference_operator attribute_name
    ;

// 6.22 <method reference>

method_reference
    : value_expression_primary dereference_operator method_name sql_argument_list
    ;

// 6.23 <reference resolution>

reference_resolution
    : 'DEREF' LEFT_PAREN reference_value_expression RIGHT_PAREN
    ;

// 6.24 <array element reference>

array_element_reference
    : array_value_expression LEFT_BRACKET_OR_TRIGRAPH numeric_value_expression RIGHT_BRACKET_OR_TRIGRAPH
    ;

// 6.25 <multiset element reference>

multiset_element_reference
    : 'ELEMENT' LEFT_PAREN multiset_value_expression RIGHT_PAREN
    ;

// 6.26 <value expression>

value_expression
    : common_value_expression
    | boolean_value_expression
    | row_value_expression
    ;

common_value_expression
    : numeric_value_expression
    | string_value_expression
    | datetime_value_expression
    | interval_value_expression
    | user_defined_type_value_expression
    | reference_value_expression
    | collection_value_expression
    ;

user_defined_type_value_expression
    : value_expression_primary
    ;

reference_value_expression
    : value_expression_primary
    ;

collection_value_expression
    : array_value_expression
    | multiset_value_expression
    ;

// 6.27 <numeric value expression>

numeric_value_expression
    : term
    | numeric_value_expression PLUS_SIGN term
    | numeric_value_expression MINUS_SIGN term
    ;

term
    : factor
    | term ASTERISK factor
    | term SOLIDUS factor
    ;

factor
    : sign? numeric_primary
    ;

numeric_primary
    : value_expression_primary
    | numeric_value_function
    ;

// 6.28 <numeric value function>

numeric_value_function
    : position_expression
    | regex_occurrences_function
    | regex_position_expression
    | extract_expression
    | length_expression
    | cardinality_expression
    | max_cardinality_expression
    | absolute_value_expression
    | modulus_expression
    | trigonometric_function
    | general_logarithm_function
    | common_logarithm
    | natural_logarithm
    | exponential_function
    | power_function
    | square_root
    | floor_function
    | ceiling_function
    | width_bucket_function
    ;

position_expression
    : character_position_expression
    | binary_position_expression
    ;

regex_occurrences_function
    : 'OCCURRENCES_REGEX' LEFT_PAREN xquery_pattern ('FLAG' xquery_option_flag)? 'IN' regex_subject_string ('FROM' start_position)? ('USING' char_length_units)? RIGHT_PAREN
    ;

xquery_pattern
    : character_value_expression
    ;

xquery_option_flag
    : character_value_expression
    ;

regex_subject_string
    : character_value_expression
    ;

regex_position_expression
    : 'POSITION_REGEX' LEFT_PAREN regex_position_start_or_after? xquery_pattern ('FLAG' xquery_option_flag)? 'IN' regex_subject_string ('FROM' start_position)? ('USING' char_length_units)? ('OCCURRENCE' regex_occurrence)? ('GROUP' regex_capture_group)? RIGHT_PAREN
    ;

regex_position_start_or_after
    : 'START'
    | 'AFTER'
    ;

regex_occurrence
    : numeric_value_expression
    ;

regex_capture_group
    : numeric_value_expression
    ;

character_position_expression
    : 'POSITION' LEFT_PAREN character_value_expression_1 'IN' character_value_expression_2 ('USING' char_length_units)? RIGHT_PAREN
    ;

character_value_expression_1
    : character_value_expression
    ;

character_value_expression_2
    : character_value_expression
    ;

binary_position_expression
    : 'POSITION' LEFT_PAREN binary_value_expression 'IN' binary_value_expression RIGHT_PAREN
    ;

length_expression
    : char_length_expression
    | octet_length_expression
    ;

char_length_expression
    : ('CHAR_LENGTH' | 'CHARACTER_LENGTH') LEFT_PAREN character_value_expression ('USING' char_length_units)? RIGHT_PAREN
    ;

octet_length_expression
    : 'OCTET_LENGTH' LEFT_PAREN string_value_expression RIGHT_PAREN
    ;

extract_expression
    : 'EXTRACT' LEFT_PAREN extract_field 'FROM' extract_source RIGHT_PAREN
    ;

extract_field
    : PRIMARY_DATETIME_FIELD
    | time_zone_field
    ;

time_zone_field
    : 'TIMEZONE_HOUR'
    | 'TIMEZONE_MINUTE'
    ;

extract_source
    : datetime_value_expression
    | interval_value_expression
    ;

cardinality_expression
    : 'CARDINALITY' LEFT_PAREN collection_value_expression RIGHT_PAREN
    ;

max_cardinality_expression
    : 'ARRAY_MAX_CARDINALITY' LEFT_PAREN array_value_expression RIGHT_PAREN
    ;

absolute_value_expression
    : 'ABS' LEFT_PAREN numeric_value_expression RIGHT_PAREN
    ;

modulus_expression
    : 'MOD' LEFT_PAREN numeric_value_expression_dividend COMMA numeric_value_expression_divisor RIGHT_PAREN
    ;

numeric_value_expression_dividend
    : numeric_value_expression
    ;

numeric_value_expression_divisor
    : numeric_value_expression
    ;

natural_logarithm
    : 'LN' LEFT_PAREN numeric_value_expression RIGHT_PAREN
    ;

exponential_function
    : 'EXP' LEFT_PAREN numeric_value_expression RIGHT_PAREN
    ;

power_function
    : 'POWER' LEFT_PAREN numeric_value_expression_base COMMA numeric_value_expression_exponent RIGHT_PAREN
    ;

numeric_value_expression_base
    : numeric_value_expression
    ;

numeric_value_expression_exponent
    : numeric_value_expression
    ;

square_root
    : 'SQRT' LEFT_PAREN numeric_value_expression RIGHT_PAREN
    ;

floor_function
    : 'FLOOR' LEFT_PAREN numeric_value_expression RIGHT_PAREN
    ;

ceiling_function
    : ('CEIL' | 'CEILING') LEFT_PAREN numeric_value_expression RIGHT_PAREN
    ;

width_bucket_function
    : 'WIDTH_BUCKET' LEFT_PAREN width_bucket_operand COMMA width_bucket_bound_1 COMMA width_bucket_bound_2 COMMA width_bucket_count RIGHT_PAREN
    ;

width_bucket_operand
    : numeric_value_expression
    ;

width_bucket_bound_1
    : numeric_value_expression
    ;

width_bucket_bound_2
    : numeric_value_expression
    ;

width_bucket_count
    : numeric_value_expression
    ;

// 6.29 <string value expression>

string_value_expression
    : character_value_expression
    | binary_value_expression
    ;

character_value_expression
    : character_value_expression CONCATENATION_OPERATOR character_factor
    | character_factor
    ;

character_factor
    : character_primary collate_clause?
    ;

character_primary
    : value_expression_primary
    | string_value_function
    ;

binary_value_expression
    : binary_value_expression CONCATENATION_OPERATOR binary_factor
    | binary_factor
    ;

binary_factor
    : binary_primary
    ;

binary_primary
    : value_expression_primary
    | string_value_function
    ;

// 6.30 <string value function>

string_value_function
    : character_value_function
    | binary_value_function
    ;

character_value_function
    : character_substring_function
    | regular_expression_substring_function
    | regex_substring_function
    | fold
    | transcoding
    | character_transliteration
    | regex_transliteration
    | trim_function
    | character_overlay_function
    | normalize_function
    | specific_type_method
    ;

character_substring_function
    : 'SUBSTRING' LEFT_PAREN character_value_expression 'FROM' start_position ('FOR' string_length)? ('USING' char_length_units)? RIGHT_PAREN
    ;

regular_expression_substring_function
    : 'SUBSTRING' LEFT_PAREN character_value_expression 'SIMILAR' character_value_expression 'ESCAPE' escape_character RIGHT_PAREN
    ;

regex_substring_function
    : 'SUBSTRING_REGEX' LEFT_PAREN xquery_pattern ('FLAG' xquery_option_flag)? 'IN' regex_subject_string ('FROM' start_position)? ('USING' char_length_units)? ('OCCURRENCE' regex_occurrence)? ('GROUP' regex_capture_group)? RIGHT_PAREN
    ;

fold
    : ('UPPER' | 'LOWER') LEFT_PAREN character_value_expression RIGHT_PAREN
    ;

transcoding
    : 'CONVERT' LEFT_PAREN character_value_expression 'USING' transcoding_name RIGHT_PAREN
    ;

character_transliteration
    : 'TRANSLATE' LEFT_PAREN character_value_expression 'USING' transliteration_name RIGHT_PAREN
    ;

regex_transliteration
    : 'TRANSLATE_REGEX' LEFT_PAREN xquery_pattern ('FLAG' xquery_option_flag)? 'IN' regex_subject_string ('WITH' xquery_replacement_string)? ('FROM' start_position)? ('USING' char_length_units)? ('OCCURRENCE' regex_transliteration_occurrence)? RIGHT_PAREN
    ;

xquery_replacement_string
    : character_value_expression
    ;

regex_transliteration_occurrence
    : regex_occurrence
    | 'ALL'
    ;

trim_function
    : 'TRIM' LEFT_PAREN trim_operands RIGHT_PAREN
    ;

trim_operands
    : (trim_specification? trim_character? 'FROM')? trim_source
    ;

trim_source
    : character_value_expression
    ;

trim_specification
    : 'LEADING'
    | 'TRAILING'
    | 'BOTH'
    ;

trim_character
    : character_value_expression
    ;

character_overlay_function
    : 'OVERLAY' LEFT_PAREN character_value_expression 'PLACING' character_value_expression 'FROM' start_position ('FOR' string_length)? ('USING' char_length_units)? RIGHT_PAREN
    ;

normalize_function
    : 'NORMALIZE' LEFT_PAREN character_value_expression (COMMA normal_form (COMMA normalize_function_result_length)?)? RIGHT_PAREN
    ;

normal_form
    : 'NFC'
    | 'NFD'
    | 'NFKC'
    | 'NFKD'
    ;

normalize_function_result_length
    : character_length
    | character_large_object_length
    ;

specific_type_method
    : user_defined_type_value_expression PERIOD 'SPECIFICTYPE' (LEFT_PAREN RIGHT_PAREN)?
    ;

binary_value_function
    : binary_substring_function
    | binary_trim_function
    | binary_overlay_function
    ;

binary_substring_function
    : 'SUBSTRING' LEFT_PAREN binary_value_expression 'FROM' start_position ('FOR' string_length)? RIGHT_PAREN
    ;

binary_trim_function
    : 'TRIM' LEFT_PAREN binary_trim_operands RIGHT_PAREN
    ;

binary_trim_operands
    : (trim_specification? trim_octet? 'FROM')? binary_trim_source
    ;

binary_trim_source
    : binary_value_expression
    ;

trim_octet
    : binary_value_expression
    ;

binary_overlay_function
    : 'OVERLAY' LEFT_PAREN binary_value_expression 'PLACING' binary_value_expression 'FROM' start_position ('FOR' string_length)? RIGHT_PAREN
    ;

start_position
    : numeric_value_expression
    ;

string_length
    : numeric_value_expression
    ;

// 6.31 <datetime value expression>

datetime_value_expression
    : datetime_term
    | interval_value_expression PLUS_SIGN datetime_term
    | datetime_value_expression PLUS_SIGN interval_term
    | datetime_value_expression MINUS_SIGN interval_term
    ;

datetime_term
    : datetime_factor
    ;

datetime_factor
    : datetime_primary time_zone?
    ;

datetime_primary
    : value_expression_primary
    | datetime_value_function
    ;

time_zone
    : 'AT' time_zone_specifier
    ;

time_zone_specifier
    : 'LOCAL'
    | 'TIME' 'ZONE' interval_primary
    ;

// 6.32 <datetime value function>

datetime_value_function
    : current_date_value_function
    | current_time_value_function
    | current_timestamp_value_function
    | current_local_time_value_function
    | current_local_timestamp_value_function
    ;

current_date_value_function
    : 'CURRENT_DATE'
    ;

current_time_value_function
    : 'CURRENT_TIME' (LEFT_PAREN time_precision RIGHT_PAREN)?
    ;

current_local_time_value_function
    : 'LOCALTIME' (LEFT_PAREN time_precision RIGHT_PAREN)?
    ;

current_timestamp_value_function
    : 'CURRENT_TIMESTAMP' (LEFT_PAREN timestamp_precision RIGHT_PAREN)?
    ;

current_local_timestamp_value_function
    : 'LOCALTIMESTAMP' (LEFT_PAREN timestamp_precision RIGHT_PAREN)?
    ;

// 6.33 <interval value expression>

interval_value_expression
    : interval_term
    | interval_value_expression PLUS_SIGN interval_term_1
    | interval_value_expression MINUS_SIGN interval_term_1
    | LEFT_PAREN datetime_value_expression MINUS_SIGN datetime_term RIGHT_PAREN INTERVAL_QUALIFIER
    ;

interval_term
    : interval_factor
    | interval_term ASTERISK factor
    | interval_term SOLIDUS factor
    | term ASTERISK interval_factor
    ;

interval_factor
    : sign? interval_primary
    ;

interval_primary
    : value_expression_primary INTERVAL_QUALIFIER?
    | interval_value_function
    ;

interval_term_1
    : interval_term
    ;

// 6.34 <interval value function>

interval_value_function
    : interval_absolute_value_function
    ;

interval_absolute_value_function
    : 'ABS' LEFT_PAREN interval_value_expression RIGHT_PAREN
    ;

// 6.35 <boolean value expression>

boolean_value_expression
    : boolean_term
    | boolean_value_expression 'OR' boolean_term
    ;

boolean_term
    : boolean_factor
    | boolean_term 'AND' boolean_factor
    ;

boolean_factor
    : 'NOT'? boolean_test
    ;

boolean_test
    : boolean_primary ('IS' 'NOT'? truth_value)?
    ;

truth_value
    : 'TRUE'
    | 'FALSE'
    | 'UNKNOWN'
    ;

boolean_primary
    : predicate
    | boolean_predicand
    ;

boolean_predicand
    : parenthesized_boolean_value_expression
    | value_expression_primary
    ;

parenthesized_boolean_value_expression
    : LEFT_PAREN boolean_value_expression RIGHT_PAREN
    ;

// 6.36 <array value expression>

array_value_expression
    : array_value_expression CONCATENATION_OPERATOR array_primary
    | array_primary
    ;

array_primary
    : array_value_function
    | value_expression_primary
    ;

// 6.37 <array value function>

array_value_function
    : trim_array_function
    ;

trim_array_function
    : 'TRIM_ARRAY' LEFT_PAREN array_value_expression COMMA numeric_value_expression RIGHT_PAREN
    ;

// 6.38 <array value constructor>

array_value_constructor
    : array_value_constructor_by_enumeration
    | array_value_constructor_by_query
    ;

array_value_constructor_by_enumeration
    : 'ARRAY' LEFT_BRACKET_OR_TRIGRAPH array_element_list RIGHT_BRACKET_OR_TRIGRAPH
    ;

array_element_list
    : array_element (COMMA array_element)*
    ;

array_element
    : value_expression
    ;

array_value_constructor_by_query
    : 'ARRAY' table_subquery
    ;

// 6.39 <multiset value expression>

multiset_value_expression
    : multiset_term
    | multiset_value_expression 'MULTISET' 'UNION' 'ALL' | 'DISTINCT'? multiset_term
    | multiset_value_expression 'MULTISET' 'EXCEPT' 'ALL' | 'DISTINCT'? multiset_term
    ;

multiset_term
    : multiset_primary
    | multiset_term 'MULTISET' 'INTERSECT' 'ALL' | 'DISTINCT'? multiset_primary
    ;

multiset_primary
    : multiset_value_function
    | value_expression_primary
    ;

// 6.40 <multiset value function>

multiset_value_function
    : multiset_set_function
    ;

multiset_set_function
    : 'SET' LEFT_PAREN multiset_value_expression RIGHT_PAREN
    ;

// 6.41 <multiset value constructor>

multiset_value_constructor
    : multiset_value_constructor_by_enumeration
    | multiset_value_constructor_by_query
    | table_value_constructor_by_query
    ;

multiset_value_constructor_by_enumeration
    : 'MULTISET' LEFT_BRACKET_OR_TRIGRAPH multiset_element_list RIGHT_BRACKET_OR_TRIGRAPH
    ;

multiset_element_list
    : multiset_element (COMMA multiset_element)*
    ;

multiset_element
    : value_expression
    ;

multiset_value_constructor_by_query
    : 'MULTISET' table_subquery
    ;

table_value_constructor_by_query
    : 'TABLE' table_subquery
    ;

// 7 Query expressions

// 7.1     <row value constructor>

row_value_constructor
    : common_value_expression
    | boolean_value_expression
    | explicit_row_value_constructor
    ;

explicit_row_value_constructor
    : LEFT_PAREN row_value_constructor_element COMMA row_value_constructor_element_list RIGHT_PAREN
    | 'ROW' LEFT_PAREN row_value_constructor_element_list RIGHT_PAREN
    | row_subquery
    ;

row_value_constructor_element_list
    : row_value_constructor_element (COMMA row_value_constructor_element)*
    ;

row_value_constructor_element
    : value_expression
    ;

contextually_typed_row_value_constructor
    : common_value_expression
    | boolean_value_expression
    | contextually_typed_value_specification
    | LEFT_PAREN contextually_typed_value_specification RIGHT_PAREN
    | LEFT_PAREN contextually_typed_row_value_constructor_element COMMA contextually_typed_row_value_constructor_element_list RIGHT_PAREN
    | 'ROW' LEFT_PAREN contextually_typed_row_value_constructor_element_list RIGHT_PAREN
    ;

contextually_typed_row_value_constructor_element_list
    : contextually_typed_row_value_constructor_element (COMMA contextually_typed_row_value_constructor_element)*
    ;

contextually_typed_row_value_constructor_element
    : value_expression
    | contextually_typed_value_specification
    ;

row_value_constructor_predicand
    : common_value_expression
    | boolean_predicand
    | explicit_row_value_constructor
    ;

// 7.2      <row value expression>

row_value_expression
    : row_value_special_case
    | explicit_row_value_constructor
    ;

table_row_value_expression
    : row_value_special_case
    | row_value_constructor
    ;

contextually_typed_row_value_expression
    : row_value_special_case
    | contextually_typed_row_value_constructor
    ;

row_value_predicand
    : row_value_special_case
    | row_value_constructor_predicand
    ;

row_value_special_case
    : value_expression_primary
    ;

// 7.3      <table value constructor>

table_value_constructor
    : 'VALUES' row_value_expression_list
    ;

row_value_expression_list
    : table_row_value_expression (COMMA table_row_value_expression)*
    ;

contextually_typed_table_value_constructor
    : 'VALUES' contextually_typed_row_value_expression_list
    ;

contextually_typed_row_value_expression_list
    : contextually_typed_row_value_expression (COMMA contextually_typed_row_value_expression)*
    ;

// 7.4      <table expression>

table_expression
    : from_clause where_clause? group_by_clause? having_clause? window_clause?
    ;

// 7.5        <from clause>

from_clause
    : 'FROM' table_reference_list
    ;

table_reference_list
    : table_reference (COMMA table_reference)*
    ;

// 7.6     <table reference>

table_reference
    : table_factor
    | table_reference 'CROSS' 'JOIN' table_factor
    | table_reference join_type? 'JOIN' (table_reference | partitioned_join_table) join_specification
    | partitioned_join_table join_type? 'JOIN' (table_reference | partitioned_join_table) join_specification
    | table_reference 'NATURAL' join_type? 'JOIN' (table_factor | partitioned_join_table)
    | partitioned_join_table 'NATURAL' join_type? 'JOIN' (table_factor | partitioned_join_table)
    | LEFT_PAREN table_reference RIGHT_PAREN
    ;

table_factor
    : table_primary sample_clause?
    ;

sample_clause
    : 'TABLESAMPLE' sample_method LEFT_PAREN sample_percentage RIGHT_PAREN repeatable_clause?
    ;

sample_method
    : 'BERNOULLI'
    | 'SYSTEM'
    ;

repeatable_clause
    : 'REPEATABLE' LEFT_PAREN repeat_argument RIGHT_PAREN
    ;

sample_percentage
    : numeric_value_expression
    ;

repeat_argument
    : numeric_value_expression
    ;

table_primary
    : table_or_query_name query_system_time_period_specification? ('AS'? correlation_name (LEFT_PAREN derived_column_list RIGHT_PAREN)?)?
    | derived_table 'AS'? correlation_name (LEFT_PAREN derived_column_list RIGHT_PAREN)?
    | lateral_derived_table 'AS'? correlation_name (LEFT_PAREN derived_column_list RIGHT_PAREN)?
    | collection_derived_table 'AS'? correlation_name (LEFT_PAREN derived_column_list RIGHT_PAREN)?
    | table_function_derived_table 'AS'? correlation_name (LEFT_PAREN derived_column_list RIGHT_PAREN)?
    | only_spec ('AS'? correlation_name (LEFT_PAREN derived_column_list RIGHT_PAREN)?)?
    | data_change_delta_table ('AS'? correlation_name (LEFT_PAREN derived_column_list RIGHT_PAREN)?)?
    ;

query_system_time_period_specification
    : 'FOR' 'SYSTEM_TIME' 'AS' 'OF' point_in_time_1
    | 'FOR' 'SYSTEM_TIME' 'BETWEEN' 'ASYMMETRIC' | 'SYMMETRIC'? point_in_time_1 'AND' point_in_time_2
    | 'FOR' 'SYSTEM_TIME' 'FROM' point_in_time_1 'TO' point_in_time_2
    ;

point_in_time_1
    : point_in_time
    ;

point_in_time_2
    : point_in_time
    ;

point_in_time
    : datetime_value_expression
    ;

only_spec
    : 'ONLY' LEFT_PAREN table_or_query_name RIGHT_PAREN
    ;

lateral_derived_table
    : 'LATERAL' table_subquery
    ;

collection_derived_table
    : 'UNNEST' LEFT_PAREN collection_value_expression (COMMA collection_value_expression)* RIGHT_PAREN ('WITH' 'ORDINALITY')?
    ;

table_function_derived_table
    : 'TABLE' LEFT_PAREN collection_value_expression RIGHT_PAREN
    ;

derived_table
    : table_subquery
    ;

table_or_query_name
    : table_name
    | query_name
    ;

derived_column_list
    : column_name_list
    ;

column_name_list
    : column_name (COMMA column_name)*
    ;

data_change_delta_table
    : result_option 'TABLE' LEFT_PAREN data_change_statement RIGHT_PAREN
    ;

data_change_statement
    : delete_statement__searched
    | insert_statement
    | merge_statement
    | update_statement__searched
    ;

result_option
    : 'FINAL'
    | 'NEW'
    | 'OLD'
    ;

// 7.7     <joined table>

partitioned_join_table
    : table_factor 'PARTITION' 'BY' partitioned_join_column_reference_list
    ;

partitioned_join_column_reference_list
    : LEFT_PAREN partitioned_join_column_reference (COMMA partitioned_join_column_reference)* RIGHT_PAREN
    ;

partitioned_join_column_reference
    : column_reference
    ;

join_specification
    : join_condition
    | named_columns_join
    ;

join_condition
    : 'ON' search_condition
    ;

named_columns_join
    : 'USING' LEFT_PAREN join_column_list RIGHT_PAREN
    ;

join_type
    : 'INNER'
    | outer_join_type 'OUTER'?
    ;

outer_join_type
    : 'LEFT'
    | 'RIGHT'
    | 'FULL'
    ;

join_column_list
    : column_name_list
    ;

// 7.8      <where clause>

where_clause
    : 'WHERE' search_condition
    ;

// 7.9     <group by clause>

group_by_clause
    : 'GROUP' 'BY' set_quantifier? grouping_element_list
    ;

grouping_element_list
    : grouping_element (COMMA grouping_element)*
    ;

grouping_element
    : ordinary_grouping_set
    | rollup_list
    | cube_list
    | grouping_sets_specification
    | empty_grouping_set
    ;

ordinary_grouping_set
    : grouping_column_reference
    | LEFT_PAREN grouping_column_reference_list RIGHT_PAREN
    ;

grouping_column_reference
    : column_reference collate_clause?
    ;

grouping_column_reference_list
    : grouping_column_reference (COMMA grouping_column_reference)*
    ;

rollup_list
    : 'ROLLUP' LEFT_PAREN ordinary_grouping_set_list RIGHT_PAREN
    ;

ordinary_grouping_set_list
    : ordinary_grouping_set (COMMA ordinary_grouping_set)*
    ;

cube_list
    : 'CUBE' LEFT_PAREN ordinary_grouping_set_list RIGHT_PAREN
    ;

grouping_sets_specification
    : 'GROUPING' 'SETS' LEFT_PAREN grouping_set_list RIGHT_PAREN
    ;

grouping_set_list
    : grouping_set (COMMA grouping_set)*
    ;

grouping_set
    : ordinary_grouping_set
    | rollup_list
    | cube_list
    | grouping_sets_specification
    | empty_grouping_set
    ;

empty_grouping_set
    : LEFT_PAREN RIGHT_PAREN
    ;

// 7.10 <having clause>

having_clause
    : 'HAVING' search_condition
    ;

// 7.11 <window clause>

window_clause
    : 'WINDOW' window_definition_list
    ;

window_definition_list
    : window_definition (COMMA window_definition)*
    ;

window_definition
    : new_window_name 'AS' window_specification
    ;

new_window_name
    : window_name
    ;

window_specification
    : LEFT_PAREN window_specification_details RIGHT_PAREN
    ;

window_specification_details
    : existing_window_name? window_partition_clause? window_order_clause? window_frame_clause?
    ;

existing_window_name
    : window_name
    ;

window_partition_clause
    : 'PARTITION' 'BY' window_partition_column_reference_list
    ;

window_partition_column_reference_list
    : window_partition_column_reference (COMMA window_partition_column_reference)*
    ;

window_partition_column_reference
    : column_reference collate_clause?
    ;

window_order_clause
    : 'ORDER' 'BY' sort_specification_list
    ;

window_frame_clause
    : window_frame_units window_frame_extent window_frame_exclusion?
    ;

window_frame_units
    : 'ROWS'
    | 'RANGE'
    | 'GROUPS'
    ;

window_frame_extent
    : window_frame_start
    | window_frame_between
    ;

window_frame_start
    : 'UNBOUNDED' 'PRECEDING'
    | window_frame_preceding
    | 'CURRENT' 'ROW'
    ;

window_frame_preceding
    : unsigned_value_specification 'PRECEDING'
    ;

window_frame_between
    : 'BETWEEN' window_frame_bound_1 'AND' window_frame_bound_2
    ;

window_frame_bound_1
    : window_frame_bound
    ;

window_frame_bound_2
    : window_frame_bound
    ;

window_frame_bound
    : window_frame_start
    | 'UNBOUNDED' 'FOLLOWING'
    | window_frame_following
    ;

window_frame_following
    : unsigned_value_specification 'FOLLOWING'
    ;

window_frame_exclusion
    : 'EXCLUDE' 'CURRENT' 'ROW'
    | 'EXCLUDE' 'GROUP'
    | 'EXCLUDE' 'TIES'
    | 'EXCLUDE' 'NO' 'OTHERS'
    ;

// 7.12 <query specification>

query_specification
    : 'SELECT' set_quantifier? select_list table_expression
    ;

select_list
    : ASTERISK
    | select_sublist (COMMA select_sublist)*
    ;

select_sublist
    : derived_column
    | qualified_asterisk
    ;

qualified_asterisk
    : asterisked_identifier_chain PERIOD ASTERISK
    | all_fields_reference
    ;

asterisked_identifier_chain
    : asterisked_identifier (PERIOD asterisked_identifier)*
    ;

asterisked_identifier
    : identifier
    ;

derived_column
    : value_expression as_clause?
    ;

as_clause
    : 'AS'? column_name
    ;

all_fields_reference
    : value_expression_primary PERIOD ASTERISK ('AS' LEFT_PAREN all_fields_column_name_list RIGHT_PAREN)?
    ;

all_fields_column_name_list
    : column_name_list
    ;

// 7.13 <query expression>

query_expression
    : with_clause? query_expression_body order_by_clause? result_offset_clause? fetch_first_clause?
    ;

with_clause
    : 'WITH' 'RECURSIVE'? with_list
    ;

with_list
    : with_list_element (COMMA with_list_element)*
    ;

with_list_element
    : query_name (LEFT_PAREN with_column_list RIGHT_PAREN)? 'AS' table_subquery search_or_cycle_clause?
    ;

with_column_list
    : column_name_list
    ;

query_expression_body
    : query_term
    | query_expression_body 'UNION' 'ALL' | 'DISTINCT'? corresponding_spec? query_term
    | query_expression_body 'EXCEPT' 'ALL' | 'DISTINCT'? corresponding_spec? query_term
    ;

query_term
    : query_primary
    | query_term 'INTERSECT' 'ALL' | 'DISTINCT'? corresponding_spec? query_primary
    ;

query_primary
    : simple_table
    | LEFT_PAREN query_expression_body order_by_clause? result_offset_clause? fetch_first_clause? RIGHT_PAREN
    ;

simple_table
    : query_specification
    | table_value_constructor
    | explicit_table
    ;

explicit_table
    : 'TABLE' table_or_query_name
    ;

corresponding_spec
    : 'CORRESPONDING' ('BY' LEFT_PAREN corresponding_column_list RIGHT_PAREN)?
    ;

corresponding_column_list
    : column_name_list
    ;

order_by_clause
    : 'ORDER' 'BY' sort_specification_list
    ;

result_offset_clause
    : 'OFFSET' offset_row_count ('ROW' | 'ROWS')
    ;

fetch_first_clause
    : 'FETCH' ('FIRST' | 'NEXT') fetch_first_quantity? ('ROW' | 'ROWS') ('ONLY' | 'WITH' 'TIES')
    ;

fetch_first_quantity
    : fetch_first_row_count
    | fetch_first_percentage
    ;

offset_row_count
    : simple_value_specification
    ;

fetch_first_row_count
    : simple_value_specification
    ;

fetch_first_percentage
    : simple_value_specification 'PERCENT'
    ;

// 7.14 <search or cycle clause>

search_or_cycle_clause
    : search_clause
    | cycle_clause
    | search_clause cycle_clause
    ;

search_clause
    : 'SEARCH' recursive_search_order 'SET' sequence_column
    ;

recursive_search_order
    : 'DEPTH' 'FIRST' 'BY' column_name_list
    | 'BREADTH' 'FIRST' 'BY' column_name_list
    ;

sequence_column
    : column_name
    ;

cycle_clause
    : 'CYCLE' cycle_column_list 'SET' cycle_mark_column 'TO' cycle_mark_value 'DEFAULT' non_cycle_mark_value 'USING' path_column
    ;

cycle_column_list
    : cycle_column (COMMA cycle_column)*
    ;

cycle_column
    : column_name
    ;

cycle_mark_column
    : column_name
    ;

path_column
    : column_name
    ;

cycle_mark_value
    : value_expression
    ;

non_cycle_mark_value
    : value_expression
    ;

// 7.15 <subquery>

scalar_subquery
    : subquery
    ;

row_subquery
    : subquery
    ;

table_subquery
    : subquery
    ;

subquery
    : LEFT_PAREN query_expression RIGHT_PAREN
    ;

// 8 Predicates

// 8.1      <predicate>

predicate
    : comparison_predicate
    | between_predicate
    | in_predicate
    | like_predicate
    | similar_predicate
    | regex_like_predicate
    | null_predicate
    | quantified_comparison_predicate
    | exists_predicate
    | unique_predicate
    | normalized_predicate
    | match_predicate
    | overlaps_predicate
    | distinct_predicate
    | member_predicate
    | submultiset_predicate
    | set_predicate
    | type_predicate
    | period_predicate
    ;

// 8.2        <comparison predicate>

comparison_predicate
    : row_value_predicand comparison_predicate_part_2
    ;

comparison_predicate_part_2
    : comp_op row_value_predicand
    ;

comp_op
    : EQUALS_OPERATOR
    | NOT_EQUALS_OPERATOR
    | LESS_THAN_OPERATOR
    | GREATER_THAN_OPERATOR
    | LESS_THAN_OR_EQUALS_OPERATOR
    | GREATER_THAN_OR_EQUALS_OPERATOR
    ;

// 8.3      <between predicate>

between_predicate
    : row_value_predicand between_predicate_part_2
    ;

between_predicate_part_2
    : 'NOT'? 'BETWEEN' 'ASYMMETRIC' | 'SYMMETRIC'? row_value_predicand 'AND' row_value_predicand
    ;

// 8.4      <in predicate>

in_predicate
    : row_value_predicand in_predicate_part_2
    ;

in_predicate_part_2
    : 'NOT'? 'IN' in_predicate_value
    ;

in_predicate_value
    : table_subquery
    | LEFT_PAREN in_value_list RIGHT_PAREN
    ;

in_value_list
    : row_value_expression (COMMA row_value_expression)*
    ;

// 8.5        <like predicate>

like_predicate
    : character_like_predicate
    | octet_like_predicate
    ;

character_like_predicate
    : row_value_predicand character_like_predicate_part_2
    ;

character_like_predicate_part_2
    : 'NOT'? 'LIKE' character_pattern ('ESCAPE' escape_character)?
    ;

character_pattern
    : character_value_expression
    ;

escape_character
    : character_value_expression
    ;

octet_like_predicate
    : row_value_predicand octet_like_predicate_part_2
    ;

octet_like_predicate_part_2
    : 'NOT'? 'LIKE' octet_pattern ('ESCAPE' escape_octet)?
    ;

octet_pattern
    : binary_value_expression
    ;

escape_octet
    : binary_value_expression
    ;

// 8.6     <similar predicate>

similar_predicate
    : row_value_predicand similar_predicate_part_2
    ;

similar_predicate_part_2
    : 'NOT'? 'SIMILAR' 'TO' similar_pattern ('ESCAPE' escape_character)?
    ;

similar_pattern
    : character_value_expression
    ;

regular_expression
    : regular_term
    | regular_expression VERTICAL_BAR regular_term
    ;

regular_term
    : regular_factor
    | regular_term regular_factor
    ;

regular_factor
    : regular_primary
    | regular_primary ASTERISK
    | regular_primary PLUS_SIGN
    | regular_primary QUESTION_MARK
    | regular_primary repeat_factor
    ;

repeat_factor
    : LEFT_BRACE low_value upper_limit? RIGHT_BRACE
    ;

upper_limit
    : COMMA high_value?
    ;

low_value
    : UNSIGNED_INTEGER
    ;

high_value
    : UNSIGNED_INTEGER
    ;

regular_primary
    : character_specifier
    | PERCENT
    | regular_character_set
    | LEFT_PAREN regular_expression RIGHT_PAREN
    ;

character_specifier
    : NON_ESCAPED_CHARACTER
    | ESCAPED_CHARACTER
    ;

NON_ESCAPED_CHARACTER
    : .
    ;

ESCAPED_CHARACTER
    : '\\' .
    ;

regular_character_set
    : UNDERSCORE
    | LEFT_BRACKET character_enumeration+ RIGHT_BRACKET
    | LEFT_BRACKET CIRCUMFLEX character_enumeration+ RIGHT_BRACKET
    | LEFT_BRACKET character_enumeration_include+ CIRCUMFLEX character_enumeration_exclude+ RIGHT_BRACKET
    ;

character_enumeration_include
    : character_enumeration
    ;

character_enumeration_exclude
    : character_enumeration
    ;

character_enumeration
    : character_specifier
    | character_specifier MINUS_SIGN character_specifier
    | LEFT_BRACKET COLON regular_character_set_identifier COLON RIGHT_BRACKET
    ;

regular_character_set_identifier
    : identifier
    ;

// 8.7        <regex like predicate>

regex_like_predicate
    : row_value_predicand regex_like_predicate_part_2
    ;

regex_like_predicate_part_2
    : 'NOT'? 'LIKE_REGEX' xquery_pattern ('FLAG' xquery_option_flag)?
    ;

// 8.8        <null predicate>

null_predicate
    : row_value_predicand null_predicate_part_2
    ;

null_predicate_part_2
    : 'IS' 'NOT'? 'NULL'
    ;

// 8.9        <quantified comparison predicate>

quantified_comparison_predicate
    : row_value_predicand quantified_comparison_predicate_part_2
    ;

quantified_comparison_predicate_part_2
    : comp_op quantifier table_subquery
    ;

quantifier
    : all
    | some
    ;

all
    : 'ALL'
    ;

some
    : 'SOME'
    | 'ANY'
    ;

// 8.10 <exists predicate>

exists_predicate
    : 'EXISTS' table_subquery
    ;

// 8.11 <unique predicate>

unique_predicate
    : 'UNIQUE' table_subquery
    ;

// 8.12 <normalized predicate>

normalized_predicate
    : row_value_predicand normalized_predicate_part_2
    ;

normalized_predicate_part_2
    : 'IS' 'NOT'? normal_form? 'NORMALIZED'
    ;

// 8.13 <match predicate>

match_predicate
    : row_value_predicand match_predicate_part_2
    ;

match_predicate_part_2
    : 'MATCH' 'UNIQUE'? 'SIMPLE' | 'PARTIAL' | 'FULL'? table_subquery
    ;

// 8.14 <overlaps predicate>

overlaps_predicate
    : overlaps_predicate_part_1 overlaps_predicate_part_2
    ;

overlaps_predicate_part_1
    : row_value_predicand_1
    ;

overlaps_predicate_part_2
    : 'OVERLAPS' row_value_predicand_2
    ;

row_value_predicand_1
    : row_value_predicand
    ;

row_value_predicand_2
    : row_value_predicand
    ;

// 8.15 <distinct predicate>

distinct_predicate
    : row_value_predicand_3 distinct_predicate_part_2
    ;

distinct_predicate_part_2
    : 'IS' 'NOT'? 'DISTINCT' 'FROM' row_value_predicand_4
    ;

row_value_predicand_3
    : row_value_predicand
    ;

row_value_predicand_4
    : row_value_predicand
    ;

// 8.16 <member predicate>

member_predicate
    : row_value_predicand member_predicate_part_2
    ;

member_predicate_part_2
    : 'NOT'? 'MEMBER' 'OF'? multiset_value_expression
    ;

// 8.17 <submultiset predicate>

submultiset_predicate
    : row_value_predicand submultiset_predicate_part_2
    ;

submultiset_predicate_part_2
    : 'NOT'? 'SUBMULTISET' 'OF'? multiset_value_expression
    ;

// 8.18 <set predicate>

set_predicate
    : row_value_predicand set_predicate_part_2
    ;

set_predicate_part_2
    : 'IS' 'NOT'? 'A' 'SET'
    ;

// 8.19 <type predicate>

type_predicate
    : row_value_predicand type_predicate_part_2
    ;

type_predicate_part_2
    : 'IS' 'NOT'? 'OF' LEFT_PAREN type_list RIGHT_PAREN
    ;

type_list
    : user_defined_type_specification (COMMA user_defined_type_specification)*
    ;

user_defined_type_specification
    : inclusive_user_defined_type_specification
    | exclusive_user_defined_type_specification
    ;

inclusive_user_defined_type_specification
    : path_resolved_user_defined_type_name
    ;

exclusive_user_defined_type_specification
    : 'ONLY' path_resolved_user_defined_type_name
    ;

// 8.20 <period predicate>

period_predicate
    : period_overlaps_predicate
    | period_equals_predicate
    | period_contains_predicate
    | period_precedes_predicate
    | period_succeeds_predicate
    | period_immediately_precedes_predicate
    | period_immediately_succeeds_predicate
    ;

period_overlaps_predicate
    : period_predicand_1 period_overlaps_predicate_part_2
    ;

period_overlaps_predicate_part_2
    : 'OVERLAPS' period_predicand_2
    ;

period_predicand_1
    : period_predicand
    ;

period_predicand_2
    : period_predicand
    ;

period_predicand
    : period_reference
    | 'PERIOD' LEFT_PAREN period_start_value COMMA period_end_value RIGHT_PAREN
    ;

period_reference
    : basic_identifier_chain
    ;

period_start_value
    : datetime_value_expression
    ;

period_end_value
    : datetime_value_expression
    ;

period_equals_predicate
    : period_predicand_1 period_equals_predicate_part_2
    ;

period_equals_predicate_part_2
    : 'EQUALS' period_predicand_2
    ;

period_contains_predicate
    : period_predicand_1 period_contains_predicate_part_2
    ;

period_contains_predicate_part_2
    : 'CONTAINS' period_or_point_in_time_predicand
    ;

period_or_point_in_time_predicand
    : period_predicand
    | datetime_value_expression
    ;

period_precedes_predicate
    : period_predicand_1 period_precedes_predicate_part_2
    ;

period_precedes_predicate_part_2
    : 'PRECEDES' period_predicand_2
    ;

period_succeeds_predicate
    : period_predicand_1 period_succeeds_predicate_part_2
    ;

period_succeeds_predicate_part_2
    : 'SUCCEEDS' period_predicand_2
    ;

period_immediately_precedes_predicate
    : period_predicand_1 period_immediately_precedes_predicate_part_2
    ;

period_immediately_precedes_predicate_part_2
    : 'IMMEDIATELY' 'PRECEDES' period_predicand_2
    ;

period_immediately_succeeds_predicate
    : period_predicand_1 period_immediately_succeeds_predicate_part_2
    ;

period_immediately_succeeds_predicate_part_2
    : 'IMMEDIATELY' 'SUCCEEDS' period_predicand_2
    ;

// 8.21 <search condition>

search_condition
    : boolean_value_expression
    ;

// 10 Additional common elements

// 10.1 <interval qualifier>

INTERVAL_QUALIFIER
    : START_FIELD 'TO' END_FIELD
    | SINGLE_DATETIME_FIELD
    ;

START_FIELD
    : NON_SECOND_PRIMARY_DATETIME_FIELD (LEFT_PAREN INTERVAL_LEADING_FIELD_PRECISION RIGHT_PAREN)?
    ;

END_FIELD
    : NON_SECOND_PRIMARY_DATETIME_FIELD
    | 'SECOND' (LEFT_PAREN INTERVAL_FRACTIONAL_SECONDS_PRECISION RIGHT_PAREN)?
    ;

SINGLE_DATETIME_FIELD
    : NON_SECOND_PRIMARY_DATETIME_FIELD (LEFT_PAREN INTERVAL_LEADING_FIELD_PRECISION RIGHT_PAREN)?
    | 'SECOND' (LEFT_PAREN INTERVAL_LEADING_FIELD_PRECISION (COMMA INTERVAL_FRACTIONAL_SECONDS_PRECISION)? RIGHT_PAREN)?
    ;

PRIMARY_DATETIME_FIELD
    : NON_SECOND_PRIMARY_DATETIME_FIELD
    | 'SECOND'
    ;

NON_SECOND_PRIMARY_DATETIME_FIELD
    : 'YEAR'
    | 'MONTH'
    | 'DAY'
    | 'HOUR'
    | 'MINUTE'
    ;

INTERVAL_FRACTIONAL_SECONDS_PRECISION
    : UNSIGNED_INTEGER
    ;

INTERVAL_LEADING_FIELD_PRECISION
    : UNSIGNED_INTEGER
    ;

// 10.2 <language clause>

language_clause
    : 'LANGUAGE' language_name
    ;

language_name
    : 'ADA'
    | 'C'
    | 'COBOL'
    | 'FORTRAN'
    | 'M'
    | 'MUMPS'
    | 'PASCAL'
    | 'PLI'
    | 'SQL'
    ;

// 10.3 <path specification>

path_specification
    : 'PATH' schema_name_list
    ;

schema_name_list
    : schema_name (COMMA schema_name)*
    ;

// 10.4 <routine invocation>

routine_invocation
    : routine_name sql_argument_list
    ;

routine_name
    : (schema_name PERIOD)? qualified_identifier
    ;

sql_argument_list
    : LEFT_PAREN (sql_argument (COMMA sql_argument)*)? RIGHT_PAREN
    ;

sql_argument
    : value_expression
    | generalized_expression
    | target_specification
    | contextually_typed_value_specification
    | named_argument_specification
    ;

generalized_expression
    : value_expression 'AS' path_resolved_user_defined_type_name
    ;

named_argument_specification
    : sql_parameter_name NAMED_ARGUMENT_ASSIGNMENT_TOKEN named_argument_sql_argument
    ;

named_argument_sql_argument
    : value_expression
    | target_specification
    | contextually_typed_value_specification
    ;

// 10.5 <character set specification>

character_set_specification
    : standard_character_set_name
    | implementation_defined_character_set_name
    | user_defined_character_set_name
    ;

standard_character_set_name
    : character_set_name
    ;

implementation_defined_character_set_name
    : character_set_name
    ;

user_defined_character_set_name
    : character_set_name
    ;

// 10.6 <specific routine designator>

specific_routine_designator
    : 'SPECIFIC' routine_type specific_name
    | routine_type member_name ('FOR' schema_resolved_user_defined_type_name)?
    ;

routine_type
    : 'ROUTINE'
    | 'FUNCTION'
    | 'PROCEDURE'
    | 'INSTANCE' | 'STATIC' | 'CONSTRUCTOR'? 'METHOD'
    ;

member_name
    : member_name_alternatives data_type_list?
    ;

member_name_alternatives
    : schema_qualified_routine_name
    | method_name
    ;

data_type_list
    : LEFT_PAREN (data_type (COMMA data_type)*)? RIGHT_PAREN
    ;

// 10.7 <collate clause>

collate_clause
    : 'COLLATE' collation_name
    ;

// 10.8 <constraint name definition> and <constraint characteristics>

constraint_name_definition
    : 'CONSTRAINT' constraint_name
    ;

constraint_characteristics
    : constraint_check_time ('NOT'? 'DEFERRABLE')? constraint_enforcement?
    | 'NOT'? 'DEFERRABLE' constraint_check_time? constraint_enforcement?
    | constraint_enforcement
    ;

constraint_check_time
    : 'INITIALLY' 'DEFERRED'
    | 'INITIALLY' 'IMMEDIATE'
    ;

constraint_enforcement
    : 'NOT'? 'ENFORCED'
    ;

// 10.9 <aggregate function>

aggregate_function
    : 'COUNT' LEFT_PAREN ASTERISK RIGHT_PAREN filter_clause?
    | general_set_function filter_clause?
    | binary_set_function filter_clause?
    | ordered_set_function filter_clause?
    | array_aggregate_function filter_clause?
    ;

general_set_function
    : set_function_type LEFT_PAREN set_quantifier? value_expression RIGHT_PAREN
    ;

set_function_type
    : computational_operation
    ;

computational_operation
    : 'AVG'
    | 'MAX'
    | 'MIN'
    | 'SUM'
    | 'EVERY'
    | 'ANY'
    | 'SOME'
    | 'COUNT'
    | 'STDDEV_POP'
    | 'STDDEV_SAMP'
    | 'VAR_SAMP'
    | 'VAR_POP'
    | 'COLLECT'
    | 'FUSION'
    | 'INTERSECTION'
    ;

set_quantifier
    : 'DISTINCT'
    | 'ALL'
    ;

filter_clause
    : 'FILTER' LEFT_PAREN 'WHERE' search_condition RIGHT_PAREN
    ;

binary_set_function
    : binary_set_function_type LEFT_PAREN dependent_variable_expression COMMA independent_variable_expression RIGHT_PAREN
    ;

binary_set_function_type
    : 'COVAR_POP'
    | 'COVAR_SAMP'
    | 'CORR'
    | 'REGR_SLOPE'
    | 'REGR_INTERCEPT'
    | 'REGR_COUNT'
    | 'REGR_R2'
    | 'REGR_AVGX'
    | 'REGR_AVGY'
    | 'REGR_SXX'
    | 'REGR_SYY'
    | 'REGR_SXY'
    ;

dependent_variable_expression
    : numeric_value_expression
    ;

independent_variable_expression
    : numeric_value_expression
    ;

ordered_set_function
    : hypothetical_set_function
    | inverse_distribution_function
    ;

hypothetical_set_function
    : rank_function_type LEFT_PAREN hypothetical_set_function_value_expression_list RIGHT_PAREN within_group_specification
    ;

within_group_specification
    : 'WITHIN' 'GROUP' LEFT_PAREN 'ORDER' 'BY' sort_specification_list RIGHT_PAREN
    ;

hypothetical_set_function_value_expression_list
    : value_expression (COMMA value_expression)*
    ;

inverse_distribution_function
    : inverse_distribution_function_type LEFT_PAREN inverse_distribution_function_argument RIGHT_PAREN within_group_specification
    ;

inverse_distribution_function_argument
    : numeric_value_expression
    ;

inverse_distribution_function_type
    : 'PERCENTILE_CONT'
    | 'PERCENTILE_DISC'
    ;

array_aggregate_function
    : 'ARRAY_AGG' LEFT_PAREN value_expression ('ORDER' 'BY' sort_specification_list)? RIGHT_PAREN
    ;

// 10.10 <sort specification list>

sort_specification_list
    : sort_specification (COMMA sort_specification)*
    ;

sort_specification
    : sort_key ordering_specification? null_ordering?
    ;

sort_key
    : value_expression
    ;

ordering_specification
    : 'ASC'
    | 'DESC'
    ;

null_ordering
    : 'NULLS' 'FIRST'
    | 'NULLS' 'LAST'
    ;

// 14 Data manipulation

// 14.1 <declare cursor>

declare_cursor
    : 'DECLARE' cursor_name cursor_properties 'FOR' cursor_specification
    ;

// 14.2 <cursor properties>

cursor_properties
    : cursor_sensitivity? cursor_scrollability? 'CURSOR' cursor_holdability? cursor_returnability?
    ;

cursor_sensitivity
    : 'SENSITIVE'
    | 'INSENSITIVE'
    | 'ASENSITIVE'
    ;

cursor_scrollability
    : 'SCROLL'
    | 'NO' 'SCROLL'
    ;

cursor_holdability
    : 'WITH' 'HOLD'
    | 'WITHOUT' 'HOLD'
    ;

cursor_returnability
    : 'WITH' 'RETURN'
    | 'WITHOUT' 'RETURN'
    ;

// 14.3 <cursor specification>

cursor_specification
    : query_expression updatability_clause?
    ;

updatability_clause
    : 'FOR' ('READ' 'ONLY' | 'UPDATE' ('OF' column_name_list)?)
    ;

// 14.4 <open statement>

open_statement
    : 'OPEN' cursor_name
    ;

// 14.5 <fetch statement>

fetch_statement
    : 'FETCH' (fetch_orientation? 'FROM')? cursor_name 'INTO' fetch_target_list
    ;

fetch_orientation
    : 'NEXT'
    | 'PRIOR'
    | 'FIRST'
    | 'LAST'
    | ('ABSOLUTE' | 'RELATIVE') simple_value_specification
    ;

fetch_target_list
    : target_specification (COMMA target_specification)*
    ;

// 14.6 <close statement>

close_statement
    : 'CLOSE' cursor_name
    ;

// 14.7 <select statement: single row>

select_statement__single_row
    : 'SELECT' set_quantifier? select_list 'INTO' select_target_list table_expression
    ;

select_target_list
    : target_specification (COMMA target_specification)*
    ;

// 14.8 <delete statement: positioned>

delete_statement__positioned
    : 'DELETE' 'FROM' target_table ('AS'? correlation_name)? 'WHERE' 'CURRENT' 'OF' cursor_name
    ;

target_table
    : table_name
    | 'ONLY' LEFT_PAREN table_name RIGHT_PAREN
    ;

// 14.9 <delete statement: searched>

delete_statement__searched
    : 'DELETE' 'FROM' target_table ('FOR' 'PORTION' 'OF' application_time_period_name 'FROM' point_in_time_1 'TO' point_in_time_2)? ('AS'? correlation_name)? ('WHERE' search_condition)?
    ;

// 14.10 <truncate table statement>

truncate_table_statement
    : 'TRUNCATE' 'TABLE' target_table identity_column_restart_option?
    ;

identity_column_restart_option
    : 'CONTINUE' 'IDENTITY'
    | 'RESTART' 'IDENTITY'
    ;

// 14.11 <insert statement>

insert_statement
    : 'INSERT' 'INTO' insertion_target insert_columns_and_source
    ;

insertion_target
    : table_name
    ;

insert_columns_and_source
    : from_subquery
    | from_constructor
    | from_default
    ;

from_subquery
    : (LEFT_PAREN insert_column_list RIGHT_PAREN)? override_clause? query_expression
    ;

from_constructor
    : (LEFT_PAREN insert_column_list RIGHT_PAREN)? override_clause? contextually_typed_table_value_constructor
    ;

override_clause
    : 'OVERRIDING' 'USER' 'VALUE'
    | 'OVERRIDING' 'SYSTEM' 'VALUE'
    ;

from_default
    : 'DEFAULT' 'VALUES'
    ;

insert_column_list
    : column_name_list
    ;

// 14.12 <merge statement>

merge_statement
    : 'MERGE' 'INTO' target_table ('AS'? merge_correlation_name)? 'USING' table_reference 'ON' search_condition merge_operation_specification
    ;

merge_correlation_name
    : correlation_name
    ;

merge_operation_specification
    : merge_when_clause+
    ;

merge_when_clause
    : merge_when_matched_clause
    | merge_when_not_matched_clause
    ;

merge_when_matched_clause
    : 'WHEN' 'MATCHED' ('AND' search_condition)? 'THEN' merge_update_or_delete_specification
    ;

merge_update_or_delete_specification
    : merge_update_specification
    | merge_delete_specification
    ;

merge_when_not_matched_clause
    : 'WHEN' 'NOT' 'MATCHED' ('AND' search_condition)? 'THEN' merge_insert_specification
    ;

merge_update_specification
    : 'UPDATE' 'SET' set_clause_list
    ;

merge_delete_specification
    : 'DELETE'
    ;

merge_insert_specification
    : 'INSERT' (LEFT_PAREN insert_column_list RIGHT_PAREN)? override_clause? 'VALUES' merge_insert_value_list
    ;

merge_insert_value_list
    : LEFT_PAREN merge_insert_value_element (COMMA merge_insert_value_element)* RIGHT_PAREN
    ;

merge_insert_value_element
    : value_expression
    | contextually_typed_value_specification
    ;

// 14.13 <update statement: positioned>

update_statement__positioned
    : 'UPDATE' target_table ('AS'? correlation_name)? 'SET' set_clause_list 'WHERE' 'CURRENT' 'OF' cursor_name
    ;

// 14.14 <update statement: searched>

update_statement__searched
    : 'UPDATE' target_table ('FOR' 'PORTION' 'OF' application_time_period_name 'FROM' point_in_time_1 'TO' point_in_time_2)? ('AS'? correlation_name)? 'SET' set_clause_list ('WHERE' search_condition)?
    ;

// 14.15 <set clause list>

set_clause_list
    : set_clause (COMMA set_clause)*
    ;

set_clause
    : multiple_column_assignment
    | set_target EQUALS_OPERATOR update_source
    ;

set_target
    : update_target
    | mutated_set_clause
    ;

multiple_column_assignment
    : set_target_list EQUALS_OPERATOR assigned_row
    ;

set_target_list
    : LEFT_PAREN set_target (COMMA set_target)* RIGHT_PAREN
    ;

assigned_row
    : contextually_typed_row_value_expression
    ;

update_target
    : object_column
    | object_column LEFT_BRACKET_OR_TRIGRAPH simple_value_specification RIGHT_BRACKET_OR_TRIGRAPH
    ;

object_column
    : column_name
    ;

mutated_set_clause
    : object_column PERIOD method_name
    | mutated_set_clause PERIOD method_name
    ;

update_source
    : value_expression
    | contextually_typed_value_specification
    ;

// 16 Control statements

// 16.1 <call statement>

call_statement
    : 'CALL' routine_invocation
    ;

// 16.2 <return statement>

return_statement
    : 'RETURN' return_value
    ;

return_value
    : value_expression
    | 'NULL'
    ;

// 17 Transaction management

// 17.1 <start transaction statement>

start_transaction_statement
    : 'START' 'TRANSACTION' (transaction_mode (COMMA transaction_mode)*)?
    ;

// 17.2 <set transaction statement>

set_transaction_statement
    : 'SET' 'LOCAL'? 'TRANSACTION' transaction_characteristics
    ;

// 17.3 <transaction characteristics>

transaction_characteristics
    : (transaction_mode (COMMA transaction_mode)*)?
    ;

transaction_mode
    : isolation_level
    | transaction_access_mode
    | diagnostics_size
    ;

transaction_access_mode
    : 'READ' 'ONLY'
    | 'READ' 'WRITE'
    ;

isolation_level
    : 'ISOLATION' 'LEVEL' level_of_isolation
    ;

level_of_isolation
    : 'READ' 'UNCOMMITTED'
    | 'READ' 'COMMITTED'
    | 'REPEATABLE' 'READ'
    | 'SERIALIZABLE'
    ;

diagnostics_size
    : 'DIAGNOSTICS' 'SIZE' number_of_conditions
    ;

number_of_conditions
    : simple_value_specification
    ;

// 17.4 <set constraints mode statement>

set_constraints_mode_statement
    : 'SET' 'CONSTRAINTS' constraint_name_list ('DEFERRED' | 'IMMEDIATE')
    ;

constraint_name_list
    : 'ALL'
    | constraint_name (COMMA constraint_name)*
    ;

// 17.5 <savepoint statement>

savepoint_statement
    : 'SAVEPOINT' savepoint_specifier
    ;

savepoint_specifier
    : savepoint_name
    ;

// 17.6 <release savepoint statement>

release_savepoint_statement
    : 'RELEASE' 'SAVEPOINT' savepoint_specifier
    ;

// 17.7 <commit statement>

commit_statement
    : 'COMMIT' 'WORK'? ('AND' 'NO'? 'CHAIN')?
    ;

// 17.8 <rollback statement>

rollback_statement
    : 'ROLLBACK' 'WORK'? ('AND' 'NO'? 'CHAIN')? savepoint_clause?
    ;

savepoint_clause
    : 'TO' 'SAVEPOINT' savepoint_specifier
    ;

direct_sql_statement
    : directly_executable_statement SEMICOLON
    ;

directly_executable_statement
    : direct_sql_data_statement
    ;

direct_sql_data_statement
    : delete_statement__searched
    | direct_select_statement__multiple_rows
    | insert_statement
    | update_statement__searched
    | truncate_table_statement
    | merge_statement
    ;

direct_select_statement__multiple_rows
    : cursor_specification
    ;

// SQL:2011 needed definitions in parts not generated.

// 11 Schema definition and manipulation

// 11.3 <table definition>

application_time_period_name
    : identifier
    ;

// 21 Embedded SQL

// 21.1 <embedded SQL host program>

embedded_variable_name
    : COLON identifier
    ;

// SQL:2016 6.30 <numeric value function>

trigonometric_function
    : trigonometric_function_name LEFT_PAREN numeric_value_expression RIGHT_PAREN
    ;

trigonometric_function_name
    : 'SIN'
    | 'COS'
    | 'TAN'
    | 'SINH'
    | 'COSH'
    | 'TANH'
    | 'ASIN'
    | 'ACOS'
    | 'ATAN'
    ;

general_logarithm_function
    : 'LOG' LEFT_PAREN general_logarithm_base COMMA general_logarithm_argument RIGHT_PAREN
    ;

general_logarithm_base
    : numeric_value_expression
    ;

general_logarithm_argument
    : numeric_value_expression
    ;

common_logarithm
    : 'LOG10' LEFT_PAREN numeric_value_expression RIGHT_PAREN
    ;