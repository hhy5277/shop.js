CrowdControl = require 'crowdcontrol'
m = require '../mediator'
Events = require '../events'

module.exports = class CheckoutForm extends CrowdControl.Views.Form
  tag:  'checkout'
  html: '''
    <form onsubmit={submit}>
      <yield/>
    </form>
  '''

  errorMessage: ''
  loading: false
  checkedOut: false

  configs: require './config'

  _submit: (event)->
    if @loading || @checkedOut
      return

    @loading = true
    m.trigger Events.Submit, @tag

    @errorMessage = ''

    @update()
    @client.account.exists(@data.get 'user.email').then((res)=>
      if res.exists
        @data.set 'user.id', @data.get 'user.email'

      @update()
      @cart.checkout().then((pRef)=>
        pRef.p.catch (err)=>
          window?.Raven?.captureException(err)

          hasErrored = true
          @loading = false
          console.log "checkout submit Error: #{err}"
          @errorMessage = 'Unable to complete your transaction. Please try again later.'

          m.trigger Events.SubmitFailed, @tag
          @update()

        hasErrored = false
        setTimeout =>
          if !hasErrored
            @loading = false
            store.clear()

            @checkedOut = true
            @update()
        , 200

        m.trigger Events.SubmitSuccess, @tag

      ).catch (err)=>
        @loading = false
        console.log "authorize submit Error: #{err}"

        if err.type == 'authorization-error'
          @errorMessage = err.message
        else
          window?.Raven?.captureException(err)
          @errorMessage = 'Unable to complete your transaction. Please try again later.'

        m.trigger Events.SubmitFailed, @tag
        @update()
    ).catch (err)->
      @loading = false
      console.log "authorize submit Error: #{err}"

      if err.type == 'authorization-error'
        @errorMessage = err.message
      else
        window?.Raven?.captureException(err)
        @errorMessage = 'Unable to complete your transaction. Please try again later.'

      m.trigger Events.SubmitFailed, @tag
      @update()
