# really just marker objects
exports.PreambleNode = class PreambleNode
  toString: ->
    "<PreambleNode>"

exports.StringNode = class StringNode
  toString: ->
    "<StringNode>#{ @key if @key?}"

exports.EntryNode = class EntryNode
  toString: ->
    "<StringNode>#{ @key if @key?}"

exports.EntryKeyNode = class EntryKeyNode
  toString: ->
    "#{@value}"

exports.KeyValueNode = class KeyValueNode
  toString: ->
    "#{@key}: #{@value}"

exports.LiteralNode = class LiteralNode
  toString: ->
    "<LiteralNode> #{@value}"

exports.NumberNode = class NumberNode
  toString: ->
    "<NumberNode> #{@value}"

exports.QuotedLiteralNode = class QuotedLiteralNode
  toString: ->
    "<QuotedLiteralNode> #{@value}"

exports.ConcatenationNode = class ConcatenationNode
  toString: ->
    "<ConcatenationNode> #{@lhs} #{@rhs}"
