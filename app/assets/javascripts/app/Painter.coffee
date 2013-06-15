define ['jquery', 'kinetic', './Utils'], ($, K, Utils) ->
    class
        constructor: (@container) ->

        # Represents the main layer.
        mainLayer = null
        # Represents the labels container.
        labels = {}
        # Represents the color use for painting.
        colors =
            white: '#FFFFFF'
            black: '#000000'
            blue: '#8ED8F8'
            red: '#F8278E'

        K.Rect::rightX = ->
            @getX() + @getWidth()

        # Represents the basic label rectangle
        basicRect = new K.Rect
            width: 30
            height: 20
            stroke: colors.black
            strokeWidth: 1.5

        # Calculate the end X coordinates of the group
        K.Group::rightX = ->
            children = @getChildren()
            x = 0
            for child in children
                if child.getClassName() is "Rect"
                    x = child.rightX()
            return x

        # Add the stage name rectangle.
        K.Group::addNameRect = (width) ->
            rect = basicRect.clone
                width: width
                fill: colors.blue
            label = new K.Text
                width: 20
                fill: colors.white
                text: @stageName
                fontFamily: 'Calibri'
                fontSize: 12
                align: 'center'
            label.setY((rect.getHeight() - label.getHeight()) / 2)

            @add rect
            @add label

        # Add label rectangle.
        K.Group::addRect = (width, color, text) ->
            x = @rightX()
            rect = basicRect.clone
                width: width
                fill: color
                x: x
                height: 20
                stroke: colors.black
                strokeWidth: 1.5
            @add rect
            if text
                label = new K.Text
                    fill: colors.black
                    fontFamily: 'Consolas'
                    fontSize: 11
                    align: 'center'
                    width: width
                    x: x

                label.labelName = text
                label.fullName = @stageName + '_' + text
                labels[label.fullName] = label
                @add label

        # Generate the fetch stage.
        fetchStage = (y) ->
            stage = new K.Group
                x: 20
                y: y
            stage.stageName = 'F'

            stage.addNameRect 80
            stage.addRect 70, colors.white, 'predPC'
            stage.addRect 340, colors.blue
            return stage

        # Generate the decode stage
        decodeStage = (y) ->
            stage = new K.Group
                x: 20
                y: y
            stage.stageName = 'D'

            stage.addNameRect 30
            stage.addRect 30, colors.white, 'stat'
            stage.addRect 30, colors.white, 'icode'
            stage.addRect 30, colors.white, 'ifun'
            stage.addRect 30, colors.white, 'rA'
            stage.addRect 30, colors.white, 'rB'
            stage.addRect 70, colors.white, 'valC'
            stage.addRect 15, colors.blue
            stage.addRect 70, colors.white, 'valP'
            stage.addRect 115, colors.blue
            stage.addRect 40, colors.white, 'pc'
            return stage

        # Generate the execute stage.
        executeStage = (y) ->
            stage = new K.Group
                x: 20
                y: y
            stage.stageName = 'E'

            stage.addNameRect 30
            stage.addRect 30, colors.white, 'stat'
            stage.addRect 30, colors.white, 'icode'
            stage.addRect 30, colors.white, 'ifun'
            stage.addRect 70, colors.white, 'valC'
            stage.addRect 70, colors.white, 'valA'
            stage.addRect 70, colors.white, 'valB'
            stage.addRect 30, colors.white, 'dstE'
            stage.addRect 30, colors.white, 'dstM'
            stage.addRect 30, colors.white, 'srcA'
            stage.addRect 30, colors.white, 'srcB'
            stage.addRect 40, colors.white, 'pc'
            return stage

        # Generate the memory stage
        memoryStage = (y) ->
            stage = new K.Group
                x: 20
                y: y
            stage.stageName = 'M'

            stage.addNameRect 30
            stage.addRect 30, colors.white, 'stat'
            stage.addRect 30, colors.white, 'icode'
            stage.addRect 30, colors.blue
            stage.addRect 30, colors.white, 'Cnd'
            stage.addRect 20, colors.blue
            stage.addRect 70, colors.white, 'valE'
            stage.addRect 70, colors.white, 'valA'
            stage.addRect 20, colors.blue
            stage.addRect 30, colors.white, 'dstE'
            stage.addRect 30, colors.white, 'dstM'
            stage.addRect 60, colors.blue
            stage.addRect 40, colors.white, 'pc'
            return stage

        # Generate the writeback stage.
        writebackStage = (y) ->
            stage = new K.Group
                x: 20
                y: y
            stage.stageName = 'W'

            stage.addNameRect 30
            stage.addRect 30, colors.white, 'stat'
            stage.addRect 30, colors.white, 'icode'
            stage.addRect 80, colors.blue
            stage.addRect 70, colors.white, 'valE'
            stage.addRect 70, colors.white, 'valM'
            stage.addRect 20, colors.blue
            stage.addRect 30, colors.white, 'dstE'
            stage.addRect 30, colors.white, 'dstM'
            stage.addRect 60, colors.blue
            stage.addRect 40, colors.white, 'pc'
            return stage

        # Render the whole container.
        render: ->
            scale = $(window).width() / 800.0
            stage = new K.Stage
                container: @container
                width: $(window).width() * 0.65
                height: 1000
                scale: scale
            mainLayer = new K.Layer()
            mainLayer.add fetchStage 270
            mainLayer.add decodeStage 210
            mainLayer.add executeStage 150
            mainLayer.add memoryStage 90
            mainLayer.add writebackStage 30
            stage.add mainLayer
            @show
                variables: {}
                reg: [0, 0, 0, 0, 0, 0, 0, 0]
                cc: [false, false, false]

        # Show all the variables.
        show: (cycle) ->
            variables = cycle.variables
            for own key, label of labels
                name = label.labelName
                value = variables[key]
                if name is 'stat'
                    str = switch value
                        when 0 then 'BUB'
                        when 1 then 'AOK'
                        when 2 then 'HLT'
                        when 3 then 'ADR'
                        when 4 then 'INS'
                        when 5 then 'PIP'
                        else 'STAT'
                    label.setText(str)
                    if str in ['AOK', 'STAT']
                        label.setFill(colors.black)
                    else if str is 'BUB'
                        label.setFill(colors.blue)
                    else
                        label.setFill(colors.red)
                else if name is 'pc'
                    if not value?
                        label.setText(name)
                    else
                        label.setText(name + '\n' + Utils.num2hex(value, 4))
                else
                    if not value?
                        label.setText(name)
                    else
                        label.setText(name + '\n' + Utils.num2hex(value, Utils.lengthFromName(name)))
                label.setY((20 - label.getHeight()) / 2)

            mainLayer.draw()
