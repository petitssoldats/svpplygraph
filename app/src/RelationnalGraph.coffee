
class RelationnalGraph

    constructor: ( parent ) ->

        @properties              = {}
        @properties.width        = 1000
        @properties.height       = 600
        @properties.datum        = []
        @properties.linkAccuracy = 3
        @properties.cacheImage   = new Array()
        @properties.scale        = upprice
        @properties.priceCat     = false
        @properties.productCat   = false

        @categories = [[],[],[],[],[],[]]

        @properties.mouseover = ->
        @properties.mouseout  = ->

        @svg   = parent.append( 'svg' )
        @main  = @svg.append('g').attr('class', 'main')

        @force = d3.layout.force()
                    .size([@properties.width, @properties.height])
                    .nodes([])
                    .linkDistance(100)
                    .charge(-60)

        @nodes = @force.nodes()
        @links = @force.links()
        @node  = @svg.selectAll(".node")
        @link  = @svg.selectAll(".link")

        @force.on("tick", @tick )

        @properties.categoriesColor = [
            {name :"Women’s",   color:"#753863"},
            {name :"Men’s",     color:"#f94142"},
            {name :"Tech",      color:"#2a638b"},
            {name :"Media",     color:"#47a3af"},
            {name :"Home",      color:"#5aaf78"},
            {name :"Art",       color:"#5ad89a"},
            {name :"Other",     color:"#535b6a"}
        ]

        return @

    update: () ->

        _self = @

        for link, index in @links
            @links.splice( 0, 1 )

        for key, item of @properties.links
            if item.products.length > 1 and item.username isnt 'forestier_mk'
                _links = createLinks( item.products, @properties.datum, @properties.linkAccuracy )
                for link in _links
                    l = findLink( link.source.id, link.target.id, @links )
                    if !l
                        @links.push( link )
                    else
                        l.source.weight *= 10
                        l.target.weight *= 10

        setRadius( @nodes, @properties.scale )

        @svg.attr( 'width',  @properties.width  )
            .attr( 'height', @properties.height )

        @force.size([@properties.width, @properties.height])

        @link = @link.data( @links )
        @node = @node.data( @nodes )

        @link.enter().insert( "line", ".node" )
             .style( 'stroke-width', 0.5 )
             .attr( "class", "link" )

        @link.exit().remove()

        @node.enter().insert( "circle", ".cursor" )
             .style( 'fill', (d,i) => d.color  )
             .style( 'stroke', (d,i) => d.color  )
             .style( 'stroke-width', 2 )
             .style( 'fill-opacity', (d,i) ->
                if !d.own
                    return 1
                else
                    return 0.5
            )
             # .style( 'stroke-opacity', 0.01 )
             .attr( "class", "node" )
            # .call( @force.drag )

        @node
             .transition()
             .duration( 1000 )
             .attr( "r", (d) -> d.radius )

        @node.on('mouseover', (d) ->

            d3.select(@)
              .transition()
              .duration( 100 )
              .style( 'fill', '#0586ff' )

            _self.properties.mouseover( d3.select(@).node(), d )

        ).on( 'mouseout', (d) ->

            d3.select(@)
              .transition()
              .duration( 100 )
              .style( 'fill', (d,i) => d.color )

            _self.properties.mouseout( d3.select(@).node(), d )

        ).on('click', (d) ->
            window.open( d.url )
            console.log d
        )

        @force.start()

        return @

    attr: ( attribut, value ) ->

        switch attribut
            when 'width'
                return @properties.width if !value?
                @properties.width = value
            when 'height'
                return @properties.height if !value?
                @properties.height = value
            when 'datum'
                return @properties.datum if !value?
                @properties.datum = value

                m = 8
                _x = d3.scale.ordinal().domain(d3.range(m)).rangePoints([0, @properties.width], 1)

                for item, index in @properties.datum

                    i = definePriceCat( item.price[0] )
                    productCategories = item.categories[1]

                    for categorie,index in @properties.categoriesColor
                        if item.categories[1] is categorie.name
                            item.color     = categorie.color
                            item.categorie = index

                    @properties.cacheImage[index] = new Image()
                    @properties.cacheImage[index].src = item.img

                    item.x      = Math.random() * @properties.width
                    item.y      = 20

                    item.cx     = _x(i)
                    item.cy     = @properties.height/2

                    item.catx     = _x(item.categorie)
                    item.caty     = @properties.height/2

                    @nodes.push item


            when 'links'
                return @properties.links if !value?
                @properties.links = value

            when 'mouseover'
                return @properties.mouseover if !value?
                @properties.mouseover = value
            when 'mouseout'
                return @properties.mouseout if !value?
                @properties.mouseout = value
            when 'scale'
                return @properties.scale if !value?
                if value is 'up'
                    @properties.scale = upprice
                else
                    @properties.scale = downprice
            when 'priceGravity'
                return @properties.priceCat if !value?
                @properties.priceCat = value
                @force.start()
            when 'productCat'
                return @properties.productCat if !value?
                @properties.productCat = value
                @force.start()

        return @

    tick: (e) =>

        # console.log e

        @link.attr( "x1", (d) -> d.source.x )
             .attr( "y1", (d) -> d.source.y )
             .attr( "x2", (d) -> d.target.x )
             .attr( "y2", (d) -> d.target.y )

        @node.attr( "cx", (d) -> d.x )
             .attr( "cy", (d) -> d.y )

        if @properties.priceCat
            @node.each( priceGravity(0.2 * e.alpha) )

        if @properties.productCat
            @node.each( categorieGravity(0.2 * e.alpha ))

        q     = d3.geom.quadtree( @nodes )
        l     = @nodes.length
        count = 0

        while count isnt l
            q.visit collide( @nodes[count] )
            count += 1

        return @

    select: ( title ) ->

        if title?

            @node.transition()
                 .duration( 100 )
                 .attr( "r", (d) -> d.radius )
                 .style( 'fill', (d,i) => setColor(d, i, @properties.datum.length) )

            _select = null

            for item in @properties.datum
                if item.title is title

                    @node.filter( (d) -> d.id is item.id)
                        .transition()
                        .duration( 100 )
                        .style( 'fill', '#0586ff' )

                    console.log item

        else

            console.log 'nope'

        return @

    ### --- PRIVATE --- ###

    upprice   = d3.scale.sqrt().domain([ 1, 20, 50, 100, 200, 500, 5000 ]).range( [ 5, 10, 15, 20, 25, 30, 40 ])
    downprice = d3.scale.sqrt().domain([ 1, 20, 50, 100, 200, 500, 5000 ]).range( [ 50, 20, 15, 10, 8, 6, 4 ])

    setColor = ( d, i, categoriesColor ) ->

        _C = null

        if !d.own

            _c = d.color

            # _c = color( i/all  )
        else
            _c = "black"

        return _c

    setRadius = (array, scale) ->

        _max = d3.max(array, (d) -> return d.price[0])

        scale.domain([ 1, 20, 50, 100, 200, 500, _max ])

        for item in array
            item.radius = scale( item.price[0] )/2

        return

    createLinks = (arrayID, arrayProduct, linkAccuracy) ->

        result = []

        for id in arrayID
            source = findProduct( id, arrayProduct )
            for ta in arrayID
                if id isnt ta
                    target = findProduct( ta, arrayProduct )

                    accuracy = 0

                    for cat, index in target.categories
                        if cat is source.categories[index]
                            accuracy += 1

                    if accuracy > linkAccuracy
                        result.push( {source: source, target: target} )
    
        return result

    findProduct = (id, arrayProduct) ->

        result = null

        for product in arrayProduct
            if product.id is id
                result = product

        return result

    findLink = ( id1, id2, links ) ->

        result = false

        for link in links
            if link.source.id is id1
                if link.target.id is id2
                    result = link
            else if link.source.id is id2
                if link.target.id is id1
                    result = link

        return result

    collide = (node) ->
        r = node.radius + 50
        nx1 = node.x - r
        nx2 = node.x + r
        ny1 = node.y - r
        ny2 = node.y + r

        return (quad, x1, y1, x2, y2) ->
          if quad.point? and quad.point isnt node
            x = node.x - quad.point.x
            y = node.y - quad.point.y
            l = Math.sqrt(x*x + y*y)
            r = node.radius + quad.point.radius

            if l < r
              l = (l - r) / l * 0.5
              node.x -= x *= l
              node.y -= y *= l
              quad.point.x += x
              quad.point.y += y

          return x1 > nx2 || x2 < nx1 || y1 > ny2 || y2 < ny1

    definePriceCat = (price) ->

        result = 0

        if 500<=price<=5000
            result = 1
        else if 200<=price<=500
            result = 2
        else if 100<=price<=200
            result = 3
        else if  50<=price<=100
            result = 4
        else if  20<=price<=50
            result = 5
        else if  1<=price<=20
            result = 6

        # console.log price, result

        return result

    priceGravity = ( alpha ) ->
        return (d) ->
            d.x += (d.cx - d.x) * alpha
            d.y += (d.cy - d.y) * alpha

    categorieGravity = (alpha) ->
        return (d) ->
            d.x += (d.catx - d.x) * alpha
            d.y += (d.caty - d.y) * alpha

    color = d3.scale.linear().range(['#fb4e07', '#1a113a'])
                
window.RelationnalGraph = RelationnalGraph