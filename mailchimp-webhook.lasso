<?=

// https://apidocs.mailchimp.com/webhooks/

local(
	action		= web_request->param('type'),
	email		= web_request->param('data[email]') || web_request->param('data[old_email]'),
	customerID	= integer(web_request->param('data[merges][CUSTOMERID]')),
	customer, customercontactlog, entry, emailunsubscribe
)

if(#customerID) => {
	#customer = customer(#customerID)
else
	#customer = customer('email' = #email)
}

match(#action) => {

	case('subscribe')
		// ignore

	case('unsubscribe')
		// add customer contact log entry
		// add to internal unsubscribe list
		#entry = 'Unsubscribed from Mailchimp list ' + web_request->param('data[list_id]')

		#emailunsubscribe = emailunsubscribe
		#emailunsubscribe(::email) = #email
		#emailunsubscribe(::dateUnsubscribed) = date
		#emailunsubscribe(::bounced) = 0
		#emailunsubscribe->save()

	case('profile')
		// ignore

	case('upemail')
		// add customer contact log entry with change
		// update email address

		#entry = 'Changed email address on Mailchimp from '
		#entry->append(web_request->param('data[old_email]'))
		#entry->append(' to ')
		#entry->append(web_request->param('data[new_email]'))
		#entry->append('.')

		#customer(::email) = web_request->param('data[new_email]')
		#customer->save()

	case('cleaned')
		// add customer contact log entry
		// only when hard bounce:
		//   add to internal unsubscribe list
		//   delete email address from customer record

		#entry = 'Cleaned email address '
		#entry->append(#email)
		#entry->append(' from Mailchimp (')
		#entry->append(web_request->param('data[reason]'))
		#entry->append(').')

		if(web_request->param('data[reason]') == 'hard') => {
			
			#emailunsubscribe = emailunsubscribe
			#emailunsubscribe(::email) = #email
			#emailunsubscribe(::dateUnsubscribed) = date
			#emailunsubscribe(::bounced) = 1
			protect => {
				handle => {
					if(error_code != 1062) => {
						// if not a duplicate key error, propagate the error
						fail(error_code, error_msg)
					}
				}
				#emailunsubscribe->save()
			}
			
			#customer(::email) = ''
			#customer->save()

		}
		
	case('campaign')
		// ignore

}

if(#entry) => {
	
		#customerContactLog = customerContactLog

		#customerContactLog(::customerID)					= #customer(::id)
		#customerContactLog(::customerContactLogMethodID)	= 28
		#customerContactLog(::created)						= date
		#customerContactLog(::modified)						= date
		#customerContactLog(::entry)						= #entry
		
		#customerContactLog->save()

}

'Thank you. (' + _date_msec + ')'

?>