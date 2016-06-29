# Lasso Mailchimp

This aspires to be an object-oriented Mailchimp v3 API wrapper for Lasso. Requires [Lasso HTTP dependency by Brad Lindsay](https://github.com/bfad/Lasso-HTTP).

Typical usage:

    local(mailchimp_list, mergefields = map)

    // merge fields
    #mergefields->insert('FNAME'		= 'First_Name')
    #mergefields->insert('LNAME'		= 'Last_Name')

    // subscribe
    #mailchimp_list = mailchimp_list('2929919ef8') // the list ID
    #mailchimp_list->subscribe('email@example.com', #mergefields)

    // unsubscribe
    #mailchimp_list->unsubscribe('email@example.com')