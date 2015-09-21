# encoding: utf-8
require 'test_helper'

class EmailProcessOutOfOfficeTest < ActiveSupport::TestCase

  test 'process with out of office check' do

    ticket = Ticket.create(
      title: 'ooo check',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'closed' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'ooo check',
      message_id: '<20150830145601.30.608881@edenhofer.zammad.com>',
      body: 'some message bounce check',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: 1,
      created_by_id: 1,
    )
    sleep 1

    # exchange out of office example #1
    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: #{ticket.subject_build('some new subject 1')}
X-MS-Has-Attach:
X-Auto-Response-Suppress: All
X-MS-Exchange-Inbox-Rules-Loop: aaa.bbb@example.com
X-MS-TNEF-Correlator:
x-olx-disclaimer: Done
x-tm-as-product-ver: SMEX-11.0.0.4179-8.000.1202-21706.006
x-tm-as-result: No--39.689200-0.000000-31
x-tm-as-user-approved-sender: Yes
x-tm-as-user-blocked-sender: No

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process( {}, email_raw_string)
    assert_equal(true, mail['x-zammad-out-of-office'.to_sym])
    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.id, ticket_p.id)
    assert_equal('closed', ticket.state.name)

    # normal follow up
    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: #{ticket.subject_build('some new subject - none')}
X-MS-Exchange-Inbox-Rules-Loop: aaa.bbb@example.com

Some Text 2"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process( {}, email_raw_string)
    assert_equal(false, mail['x-zammad-out-of-office'.to_sym])
    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.id, ticket_p.id)
    assert_equal('open', ticket_p.state.name)

    ticket = Ticket.find(ticket.id)
    ticket.state = Ticket::State.lookup(name: 'closed')
    ticket.save

    # exchange out of office example #2
    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: #{ticket.subject_build('some new subject 2')}
X-MS-Has-Attach:
X-Auto-Response-Suppress: All
X-MS-Exchange-Inbox-Rules-Loop: aaa.bbb@example.com
X-MS-TNEF-Correlator:
x-exclaimer-md-config: 8c10826d-4052-4c5c-a8e8-e09011276827

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process( {}, email_raw_string)
    assert_equal(true, mail['x-zammad-out-of-office'.to_sym])
    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.id, ticket_p.id)
    assert_equal('closed', ticket.state.name)

  end

end