define ['jquery', 'FileSaver', './Painter', './Simulator'], ($, saveAs, Painter, Simulator) ->
    # Represents the painter used for paint.
    painter = new Painter('container')
    simulator = null

    handleDropbox = (id) ->
        box = $ id
        box.on 'dragenter dragover', (e) ->
            e.stopPropagation()
            e.preventDefault()
            box.css('border-color', '#8ED8F8')
            return false

        box.on 'dragleave', (e) ->
            e.stopPropagation()
            e.preventDefault()
            box.css('border-color', '#000000')
            return false

        box.on 'drop', (e) ->
            e.stopPropagation()
            e.preventDefault()
            box.css('border-color', '#000000')

            files = e.originalEvent.dataTransfer.files
            handleFiles(box, files)
            return false

    # Handle the input files.
    handleFiles = (box, files) ->
        file = files[0]
        reader = new FileReader()
        reader.onload = (e) ->
            simulator = new Simulator(e.target.result)
            simulator.run()
            report = simulator.report.join('\n')
            console.log(report)
            # saveResult()
            box.html $('<pre>').append(e.target.result)
        reader.readAsText(file)

    # Perform the save file action.
    saveResult = ->
        blob = new(Blob ['Hello Word!'], type: "text/plain;charset=utf-8")
        saveAs(blob, "test.txt")

    # Add actions after document ready.
    $ ->
        painter.render()
        handleDropbox('#code')

    # Deal with the window resize.
    $(window).on('resize', ->
        if @resizeTimeout
            clearTimeout(@resizeTimeout)
        @resizeTimeout = setTimeout(->
            $(@).trigger 'resizeEnd'
        , 200)
    )

    $(window).on 'resizeEnd orientationChange', ->
        $('#container').empty()
        painter.render()