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

        K.Rect::rightX = ->
            @getAttr('x') + @getWidth()

        # Represents the basic label rectangle
        basicRect = new K.Rect
            width: 30
            height: 20
            stroke: colors.black
            strokeWidth: 1.5

        # Calculate the end X coordinates of the group
        K.Group::rightX = ->
            children = @getChildren()
            length = children.length
            x = 0
            for child in children
                if child.getClassName() is "Rect"
                    x = child.rightX()
            x

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
            label.setAttr 'y', (rect.getHeight() - label.getHeight()) / 2

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
            stage.addRect 275, colors.blue
            stage

        # Generate the decode stage
        decodeStage = (y) ->
            stage = new K.Group
                x: 20
                y: y
            stage.stageName = 'D'

            stage.addNameRect 30
            stage.addRect 30, colors.white, 'icode'
            stage.addRect 30, colors.white, 'ifun'
            stage.addRect 30, colors.white, 'rA'
            stage.addRect 30, colors.white, 'rB'
            stage.addRect 70, colors.white, 'valC'
            stage.addRect 15, colors.blue
            stage.addRect 70, colors.white, 'valP'
            stage.addRect 120, colors.blue
            stage

        # Generate the execute stage.
        executeStage = (y) ->
            stage = new K.Group
                x: 20
                y: y
            stage.stageName = 'E'

            stage.addNameRect 30
            stage.addRect 30, colors.white, 'icode'
            stage.addRect 30, colors.white, 'ifun'
            stage.addRect 70, colors.white, 'valC'
            stage.addRect 70, colors.white, 'valA'
            stage.addRect 70, colors.white, 'valB'
            stage.addRect 30, colors.white, 'dstE'
            stage.addRect 30, colors.white, 'dstM'
            stage.addRect 30, colors.white, 'srcA'
            stage.addRect 30, colors.white, 'srcB'
            stage

        # Generate the memory stage
        memoryStage = (y) ->
            stage = new K.Group
                x: 20
                y: y
            stage.stageName = 'M'

            stage.addNameRect 30
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
            stage

        # Generate the writeback stage.
        writebackStage = (y) ->
            stage = new K.Group
                x: 20
                y: y
            stage.stageName = 'W'

            stage.addNameRect 30
            stage.addRect 30, colors.white, 'icode'
            stage.addRect 80, colors.blue
            stage.addRect 70, colors.white, 'valE'
            stage.addRect 70, colors.white, 'valM'
            stage.addRect 20, colors.blue
            stage.addRect 30, colors.white, 'dstE'
            stage.addRect 30, colors.white, 'dstM'
            stage.addRect 60, colors.blue
            stage

        # Render the whole container.
        render: ->
            scale = $(window).width() / 900.0
            stage = new K.Stage
                container: @container
                width: $(window).width() * 0.5
                height: 1000
                scale: scale
            mainLayer = new Kinetic.Layer()
            mainLayer.add fetchStage 420
            mainLayer.add decodeStage 320
            mainLayer.add executeStage 220
            mainLayer.add memoryStage 120
            mainLayer.add writebackStage 20
            stage.add mainLayer
            @show
                F_predPC: -1

        # Show all the variables.
        show: (variables) ->
            for own key, label of labels
                name = label.labelName
                label.setAttr 'text', name + '\n' + Utils.num2hex variables[key], Utils.lengthFromName name
                label.setAttr 'y', (20 - label.getHeight()) / 2
            mainLayer.draw()


