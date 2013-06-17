define ['jquery', 'FileSaver', './Painter', './Simulator'], ($, saveAs, Painter, Simulator) ->
    # Represents the painter used for paint.
    painter = new Painter('container')
    simulator = null
    nowCircle = 1
    playing = false

    handleDropbox = (id) ->
        box = $(id)
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
            painter.show(simulator.cycles[1])
            console.log(report)
            # saveResult(report)
            box.html $('<pre>').append(e.target.result)
        reader.readAsText(file)

    # Perform the save file action.
    saveResult = (result) ->
        blob = new Blob([result], type: "text/plain;charset=utf-8")
        saveAs(blob, "result.txt")

    # Add actions after document ready.
    $ ->
        painter.render()
        handleDropbox('#code')

    show = (cycle) ->
        $('#cycle_index').html(cycle - 1)
        painter.show(simulator.cycles[cycle])

    # Deal with the next button
    $('#next').on('click', ->
        if nowCircle + 1 >= simulator.cycles.length
            alert "程序运行结束！"
        else
            show(++nowCircle)
    )

    # Deal with the prev button
    $('#prev').on('click', ->
        if nowCircle is 1
            alert "程序已经在第一个cycle！"
        else
            show(--nowCircle)
    )

    # Deal with the reset button
    $('#reset').on('click', ->
        if playing then $('#play').trigger('click')
        show(nowCircle = 1)
    )

    # Play the simulator continuously
    play = ->
        if nowCircle + 1 >= simulator.cycles.length
            playing = false
        if not playing then return
        show(++nowCircle)
        setTimeout(play, 2100 - $('#speed').val())

    $('#play').on('click', ->
        playing = not playing
        if playing
            $(@).html('pause')
            play()
        else
            $(@).html('play')
    )

    # Deal with the window resize.
    $(window).on('resize', ->
        if @resizeTimeout
            clearTimeout(@resizeTimeout)
        @resizeTimeout = setTimeout( ->
            $(@).trigger('resizeEnd')
        , 200)
    )

    $(window).on 'resizeEnd orientationChange', ->
        $('#container').empty()
        painter.render()

    $('#test').on('click', ->
        painter.f_render()
    )