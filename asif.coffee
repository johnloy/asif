# AsIf.js
# Version 0.1
# https://github.com/johnloy/asif
#
# By John Loy - loy.john[at]gmail.com
#
# License - WTFPL

AsIf = ->

  # We're building a contextualizer array
  if typeof arguments[0] == 'function'
    return _contextualizers(arguments[0])

  # We're defining a context
  else if typeof arguments[0] == 'object' && typeof arguments[1] == 'undefined'
    return _defineContext(arguments[0])

  # else if there are two arguments, an object and a function
  #   then we're extending an instance immediately

  # We're defining a polymorphic context
  else if typeof arguments[0] == 'string'
    return _definePolymorphicContext(arguments[0])


polymorphic_contexts = '*': {}


_contextualizers = (konstructor) ->
  contextualizers = {}

  for name of konstructor.__contexts
    do (name) ->
      stub_name = getPolymorphicStubName(name, konstructor)
      # The name key should be the short form poly name, while the contextualizer
      contextualizers[stub_name] = _buildContextualizer(konstructor, stub_name, contextualizers)

  # Chaining sugar
  contextualizers[i] = contextualizers for i in ['was', 'and']
  contextualizers


# Returns a function that, when called, returns a class definition 
# (i.e. JS constructor function) endowed with properties and methods
# defined for a context. This returned constructor can then be used
# like any other (e.g. new BananaPastRipeness())
_buildContextualizer = (konstructor, context_name, contextualizers) ->

  # A contextualizer is just a function. It gets called as a chained
  # function after AsIf().
  # Example: AsIf(Banana).pastRipeness() // returns a new contextualized constructor
  return (relayed_konstructor, relayed_context_name)->

    k = relayed_konstructor || konstructor
    c = relayed_context_name || context_name
    polymorphic_name = getPolymorphicName(c)
    context_definition = k.__contexts[polymorphic_name]

    class contextualized extends k
      constructor: ->
        super
        context_definition.initialize?.call(@)

    # Mixin context properties to the prototype of the new constructor
    proto = contextualized.prototype
    (proto[name] = prop) for name, prop of context_definition.extensions

    # Make contextualizers chainable
    for ctxlzr_name, ctxlzr of contextualizers
      do(ctxlzr_name, ctxlzr) ->
        _ctxlzr = if typeof ctxlzr == 'function' then (-> ctxlzr(contextualized, ctxlzr_name)) else ctxlzr
        contextualized[ctxlzr_name] = _ctxlzr 
    contextualized


_defineContext = (contexts)->

  context_name = name for name of contexts
  context = contexts[context_name]

  affects: (konstructor) ->

    # Add a namespace for the context definition, like Banana.__contexts['pastRipeness']
    konstructor.__contexts ||= {}
    context_definition = konstructor.__contexts[context_name] = {}

    # These extension properties and methods will later be added to the constructor prototype
    extensions = {}
    (extensions[name] = prop) for name, prop of context when name isnt 'initialize'
    context_definition.extensions = extensions

    # This initialize method gets called later in the 'this' context of an instance
    context_definition.initialize = context['initialize']


_definePolymorphicContext = (context_name) ->
  _konstructor = null

  poly =
    changesWith: (func) ->
      key = _konstructor || '*'
      polymorphic_contexts[key][context_name] = func

  poly['to'] = (konstructor) -> _konstructor = konstructor

  poly


# Construct a full polymorphic name using the stub name and the function
# that returns the stub completion.
getPolymorphicName = (name, konstructor) ->
  pc = polymorphic_contexts
  func = pc[konstructor]?[name] || pc['*'][name]
  name + (func?() || '')

# Deduce a context stub name for a polymorphic context name using
# substring matching.
getPolymorphicStubName = (polymorphic_name, konstructor) ->
  pc = polymorphic_contexts
  stub_name = null

  searchForStub = (scope) ->
    for k,v of scope 
      stub_name = k if polymorphic_name.substr(0, k.length) == k
    stub_name

  konstr_scope = pc[konstructor]
  searchForStub(konstr_scope) if konstr_scope
  searchForStub(pc['*']) unless stub_name

  stub_name || polymorphic_name

# Exports
window.AsIf = AsIf
