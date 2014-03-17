SEO =
  settings: {
    title: ''
    rel_author: ''
    meta: []
    og: []
    twitter: []
    ignore:
      meta: ['fragment']
      link: ['stylesheet']
    auto:
      twitter: true
      og: true
      set: ['description', 'url', 'title']
  }

  # e.g. ignore('meta', 'fragment')
  ignore: (type, value) ->
    @settings.ignore[type].push(value) if @settings.ignore[type] and _.indexOf(@settings.ignore[type], value) is -1

  config: (settings) ->
    _.extend(@settings, settings)

  set: (options) ->
    meta = options.meta
    og = options.og
    link = options.link
    twitter = options.twitter

    @setTitle options.title if options.title
    @setUrl options.url if options.url

    # set meta
    if meta and _.isArray(meta)
      for m in meta
        @setMeta("name='#{m.key}'", m.value)
    else if meta and _.isObject(meta)
      for k, v of meta
        @setMeta("name='#{k}'", v)

    # set og
    if og and _.isArray(og)
      for o in og
        @setMeta("property='og:#{o.key}'", o.value)
    else if og and _.isObject(og)
      for k, v of og
        @setMeta("property='og:#{k}'", v)

    # set link
    # as array {href: "...", rel: "..."}
    # or as object {rel: href}
    if link and _.isArray(link)
      for l in link
        @setLink(l.rel, l.href)
    else if link and _.isObject(link)
      for k, v of link
        @setLink(k, v)

    # set twitter
    if twitter and _.isArray(twitter)
      for o in twitter
        @setMeta("property='twitter:#{o.key}'", o.value)
    else if twitter and _.isObject(twitter)
      for k, v of twitter
        @setMeta("property='twitter:#{k}'", v)

    # set google+ rel author
    @setLink 'author', options.rel_author if options.rel_author

  clearAll: ->
    for m in $("meta")
      $(m).remove() if _.indexOf(SEO.settings.ignore.meta, $(m).attr('name')) is -1
    for l in $("link")
      $(l).remove() if _.indexOf(SEO.settings.ignore.link, $(l).attr('rel')) is -1
    @set(@settings)
    @setTitle(@settings.title)

  setTitle: (title) ->
    document.title = title
    if _.indexOf(@settings.auto.set, 'title') isnt -1
      if @settings.auto.twitter
        @setMeta 'property="twitter:title"', title
      if @settings.auto.og
        @setMeta 'property="og:title"', title

  setUrl: (url) ->
    if _.indexOf(@settings.auto.set, 'url') isnt -1
      if @settings.auto.twitter
        @setMeta 'property="twitter:url"', url
      if @settings.auto.og
        @setMeta 'property="og:url"', url

  setLink: (rel, href, unique=true) ->
    @removeLink(rel) if unique
    if _.isArray(href)
      for h in href
        @setLink(rel, h, false)
      return

    if href
      $('head').append("<link rel='#{rel}' href='#{href}'>")

  removeLink: (rel) ->
    $("link[rel='#{rel}']").remove()

  setMeta: (attr, content, unique=true) ->
    @removeMeta(attr) if unique
    if _.isArray(content)
      for v in content
        @setMeta(attr, v, false)
      return

    if content
      $('head').append("<meta #{attr} content='#{content}'>")

    #console.log 'indexOfAutoMeta', @settings.auto.set, attr, _.indexOf(@settings.auto.set, attr)
    name = attr.replace(/"|'/g, '').split('=')[1]
    if _.indexOf(@settings.auto.set, name) isnt -1
      if @settings.auto.twitter
        @setMeta "property='twitter:#{name}'", content
      if @settings.auto.og
        @setMeta "property='og:#{name}'", content

  removeMeta: (attr) ->
    $("meta[#{attr}]").remove()


@SEO = SEO

# IR before hooks
Router.before ->
  SEO.clearAll()
  SEO.set({url: Router.url(Router.current().route.name)})

getCurrentRouteName = ->
  router = Router.current()
  return unless router
  routeName = router.route.name
  return routeName

# Get seo settings depending on route
Deps.autorun( ->
  currentRouteName = getCurrentRouteName()
  return unless currentRouteName
  Meteor.subscribe('seoByRouteName', currentRouteName)
)

# Set seo settings depending on route
Deps.autorun( ->
  return unless SEO
  currentRouteName = getCurrentRouteName()
  settings = SeoCollection.findOne({route_name: currentRouteName}) or {}
  SEO.set(settings)
)
