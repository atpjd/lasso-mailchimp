<?=

define mailchimp => type {
	
	data
		private apikey = '', // update to your API key
		private endpoint = 'https://us1.api.mailchimp.com/3.0/' //update to your assigned API endpoint

	public hash(email::string)::string => {
		return encrypt_md5(#email->lowercase&)
	}
	
	public request(path, method, body=void) => {

		local(request, response, statuscode, statusmsg)
		
		if(#body->isnota(::void)) => {
			#body = json_serialize(#body)	
		}

		#request = http_request(
			.endpoint + #path,
			-username		= 'ATP',
			-password		= .apikey,
			-basicAuthOnly	= true,
			-postParams		= #body,
			-method			= #method
		)

		return #request->response

	}

}

define mailchimp_list => type {
	parent mailchimp
	
	data
		private listid = void
	
	public oncreate(listid::string) => {
		.listid = #listid
	}

	public unsubscribe(email::string) => {

		local(
			path	= 'lists/' + .listid + '/members/' + .hash(#email),
			method	= 'PATCH',
			body	= map,
			response
		)

		#body->insert('email_address'	= #email)
		#body->insert('status'			= 'unsubscribed')

		#response = .request(#path, #method, #body)
		
		if(#response->statuscode == 200) => {
			return true
		else
			return false
		}

	}

	public subscribe(email::string, merge::map=map) => {

		local(
			path	= 'lists/' + .listid + '/members/',
			method	= 'POST',
			body	= map,
			response
		)

		#body->insert('email_address'	= #email)
		#body->insert('status'			= 'subscribed')
		#body->insert('merge_fields'	= #merge)
		
		#response = .request(#path, #method, #body)
		
		if(#response->statuscode == 200) => {
			return true
		else
			return .resubscribe(#email, #merge)
		}

	}
	
	public resubscribe(email::string, merge::map=map) => {

		local(
			path	= 'lists/' + .listid + '/members/' + .hash(#email),
			method	= 'PATCH',
			body	= map,
			response
		)

		#body->insert('email_address'	= #email)
		#body->insert('status'			= 'subscribed')
		#body->insert('merge_fields'	= #merge)
		
		#response = .request(#path, #method, #body)
		
		if(#response->statuscode == 200) => {
			return true
		else
			return false
		}

	}
	
	public update(email::string, merge::map=map) => {

		local(
			path	= 'lists/' + .listid + '/members/' + .hash(#email),
			method	= 'PATCH',
			body	= map,
			response
		)

		#body->insert('email_address'	= #email)
		#body->insert('merge_fields'	= #merge)
		
		#response = .request(#path, #method, #body)
		
		if(#response->statuscode == 200) => {
			return true
		else
			return false
		}

	}
	
	public mergefields()::array => {

		local(
			path	= 'lists/' + .listid + '/merge-fields',
			method	= 'GET',
			response, responsemap,
			merge_fields = array
		)
		
		#response = .request(#path, #method)
		#responsemap = json_deserialize(#response->body)
		
		with i in #responsemap->get('merge_fields') do => {
			#merge_fields->insert(#i->get('tag'))
		}
		
		return #merge_fields
	}

}

?>