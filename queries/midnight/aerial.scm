; Symbols for aerial.nvim (https://github.com/stevearc/aerial.nvim).
;
; aerial nests symbols by range, and when two patterns match the same @symbol
; node it keeps whichever match comes first, so patterns for the same node
; should exclude each other (ex. `new` is a Constructor, other class methods
; are Methods), instead of relying on order.
;
; @scope is the declaration's `local` / `global` / `module` (none for bare
; declarations), for aerial's `post_parse_symbol` (ex. to hide locals).

; Classes

(class_declaration
  scope: (scope)? @scope
  name: (identifier) @name
  (#set! "kind" "Class")) @symbol

(class_method
  name: (identifier) @name
  (#eq? @name "new")
  (#set! "kind" "Constructor")) @symbol

(class_method
  static: _
  name: (identifier) @name
  (#not-eq? @name "new")
  (#set! "kind" "Function")) @symbol

(class_method
  !static
  name: (identifier) @name
  (#not-eq? @name "new")
  (#set! "kind" "Method")) @symbol

(class_field
  name: (identifier) @name
  (#set! "kind" "Field")) @symbol

; Function declarations

(function_declaration
  name: (method_index_expression) @name
  (#set! "kind" "Method")) @symbol

(function_declaration
  scope: (scope)? @scope
  name: [
    (identifier)
    (dot_index_expression)
  ] @name
  (#set! "kind" "Function")) @symbol

; Arrow functions assigned to names (only the first name / value is paired,
; ex. `local f = () -> 1`, not `local a, f = 1, () -> 2`)

(variable_declaration
  scope: (scope) @scope
  (variable_list
    .
    name: (identifier) @name)
  (expression_list
    .
    value: (arrow_function))
  (#set! "kind" "Function")) @symbol

(assignment_statement
  (variable_list
    .
    name: [
      (identifier)
      (dot_index_expression)
      (bracket_index_expression)
    ] @name)
  (expression_list
    .
    value: (arrow_function))
  (#set! "kind" "Function")) @symbol

(field
  name: [
    (identifier) @name
    (string
      (string_content) @name)
  ]
  value: (arrow_function)
  (#set! "kind" "Function")) @symbol

; Module variables. The order matches come in isn't reliable for patterns that
; match the same node, so values are every expression except arrow_function
; (the `expression` subtypes in the grammar's src/node-types.json).

(variable_declaration
  scope: (scope) @scope
  (#eq? @scope "module")
  (variable_list
    .
    name: (identifier) @name)
  (expression_list
    .
    value: [
      (binary_expression)
      (false)
      (function_call)
      (if_expression)
      (markup_element)
      (match_expression)
      (nil)
      (number)
      (parenthesized_expression)
      (string)
      (table_constructor)
      (true)
      (unary_expression)
      (vararg_expression)
      (identifier)
      (dot_index_expression)
      (bracket_index_expression)
    ])
  (#set! "kind" "Variable")) @symbol

; `module x` w/o a value
(variable_declaration
  scope: (scope) @scope
  (#eq? @scope "module")
  (#set! "kind" "Variable")
  (variable_list
    .
    name: (identifier) @name)
  .) @symbol
