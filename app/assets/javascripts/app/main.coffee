define ['jquery', 'FileSaver', './Painter', './Simulator', './Utils'], ($, saveAs, Painter, Simulator, Utils) ->
    # Represents the painter used for paint.
    painter = new Painter('container')
    simulator = new Simulator()
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
            codes = simulator.load(e.target.result)
            if codes is null then
            simulator.run()
            report = simulator.report.join('\n')
            console.log(report)
            # saveResult(report)

            table = $('<table>')
            for own key, value of codes
                tr = $('<tr>').attr('id', 'line_'+ key)
                tr.append($('<td>').html(Utils.num2hex(key, 3)).addClass('line-no'))
                tr.append($('<td>').addClass('status'))
                tr.append($('<td>').append($('<pre>').html(value)).addClass('code'))
                table.append(tr)
            box.html table
            show(1)
        reader.readAsText(file)

    # Perform the save file action.
    saveResult = (result) ->
        blob = new Blob([result], type: "text/plain;charset=utf-8")
        saveAs(blob, "result.txt")

    # Show the given cycle
    show = (cycle) ->
        $('#cycle_index').html(cycle - 1)
        painter.show(simulator.cycles[cycle])

        v = simulator.cycles[cycle].variables
        $('#code .status').empty()
        $('#code .code').removeClass('highlight')
        if v.f_pc?
            tr = $('#line_' + v.f_pc)
            tr.find('.status').html 'F'
            tr.find('.code').addClass('highlight')
        if v.D_pc?
            $('#line_' + v.D_pc + ' .status').html 'D'
        if v.E_pc?
            $('#line_' + v.E_pc + ' .status').html 'E'
        if v.M_pc?
            $('#line_' + v.M_pc + ' .status').html 'M'
        if v.W_pc?
            $('#line_' + v.W_pc + ' .status').html 'W'

    # Add actions after document ready.
    $ ->
        painter.render()
        handleDropbox('#code')

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