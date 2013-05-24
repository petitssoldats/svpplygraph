
fs       = require('fs')
async    = require('async')
svpply   = require('svpply').API
api      = new svpply()

count    = 0
userName = 'Nicolas Forestier'
# userName = 'Jeanie Choi'
# userName = "Harper Reed"
# userName = "Yotam Troim"
# userName = "Feltron"
userName = "Elodie P"

GRAPH = true

getDataForUser = ( username ) ->

	api.users.find( {"query": userName}, (data) ->

		# console.log data.response.users

		# for user in data.response.users
		# 	console.log "#{user.id} \t #{user.products_count} \t #{user.name}"

		_id = data.response.users[0].id
		# console.log data.response.users[0]

		api.users.owns( _id, (ownrq) ->

			ownsProduct = ownrq.response.products
			nbrWants    = data.response.users[0].products_count
			nbrRequest  = ~~ (nbrWants/100)
			requests    = []

			console.log nbrWants, nbrRequest

			if nbrRequest > 0
				for n in [0..nbrRequest]
					offset = n*100
					requests.push offsetRequestProductForger( _id, offset )
			else
				requests.push offsetRequestProductForger( _id, 0 )

			console.log "#{requests.length} REQUESTS"

			async.parallel( requests, (err, requestsResults) =>

				_products = []
				_result   = []

				for resreq in requestsResults
					for prod in resreq.response.products
						prod.own = false
						_products.push prod

				for ownp in ownsProduct
					ownp.own = true
					_products.push ownp

				console.log "#{_products.length} PRODUCTS \t/ #{ownsProduct.length} OWNS \t / #{resreq.response.products.length} WANTS"

				productRequests = []

				for prod in _products
					productRequests.push productRequestForger( prod )

				async.parallel( productRequests, (err, results) =>

					products = []
					users    = {}
					
					for result in results
						p = setProduct( result[0] )
						products.push p

						for user in result[1]
							u = setUser( user )
							if !users[u.id]?
								u.products  = [ p.id ]
								users[u.id] = u
							else
								users[u.id].products.push( p.id )

					fs.writeFile('products.json', JSON.stringify( products ), (err) -> 
						throw err if err 
						console.log 'PRODUCTS FILE : OK'
					)
					fs.writeFile('users.json', JSON.stringify( users ), (err) -> 
						throw err if err 
						console.log 'USERS FILE : OK'
					)
							

				)
						
			)

		)

	)

### --- ###

offsetRequestProductForger = ( _id, offset  ) ->
	return ( callback ) =>
		api.users.wants( _id, offset, (data) ->
			callback( null, data )
		)


productRequestForger = (product) ->
	return ( callback ) =>
		api.products.users(product.id, (data) ->
			count += 1
			result = []
			if data?
				result = data.response.users
				console.log "#{count} \t | #{product.id} \t- #{data.response.users.length}/#{product.saves} users"
			else
				console.log "#{count} \t | #{product.id} \t- NO DATA"
			callback(null, [product, result])
		)

setProduct = ( product, own ) ->

	item            = {}
	item.id         = product.id
	item.title      = product.page_title
	item.url        = product.page_url
	item.price      = [product.price, product.formatted_price]
	item.img        = product.image
	item.wants    	= product.saves
	item.store      = {}
	item.categories = []
	item.own 		= product.own

	item.store.id   = product.store.id
	item.store.name = product.store.name

	for cat in product.categories
		item.categories.push ( cat.name )

	return item

setUser = ( user ) ->

	item = {}
	item.id       = user.id
	item.name 	  = user.name
	item.username = user.username
	item.location = user.location
	item.url      = user.url
	item.img      = user.avatar
	item.gender   = user.gender_preference
	item.products = user.products_count
	item.network  = [user.users_following_count, user.users_followers_count]

	return item
if GRAPH
	getDataForUser( userName )
else
	for index in [200...500]
		api.users.show(index, (data) ->
			user = data.response.user
			return false if !user?
			if user.products_count > 300
				console.log "#{user.id} \t| #{user.products_count} \t | #{user.name}"
		)

api.remaining( (data) ->
	console.log "REMAINING #{data.response.remaining}"
)