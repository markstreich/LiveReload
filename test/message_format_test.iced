{ deepEqual } = require 'assert'
MessageFormat = require '../lib/messages/format'

o = (pattern, func) ->
  describe "like #{JSON.stringify pattern}", ->
    fmt = new MessageFormat(pattern)
    oo = (input, expected) ->
      desc = "should find #{JSON.stringify expected} in #{JSON.stringify input}"
      it desc, ->
        { messages } = fmt.scan(input)
        deepEqual messages, expected
    func(oo)


describe "MessageFormat", ->

  o "hello world", (oo) ->
    oo 'hello there', []
    oo 'say "hello world"', [{}]

  o "((message))\n", (oo) ->
    oo "hello there\n", [{message: "hello there"}]
    oo "hello\nthere\n", [{message: "hello"}, {message: "there"}]

  o "((file)):((line)) ((message))\n", (oo) ->
    oo "foo.c:12 syntax error\n", [{message: "syntax error", file: "foo.c", line: "12"}]