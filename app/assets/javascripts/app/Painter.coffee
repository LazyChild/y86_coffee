define ['jquery', 'kinetic', './Utils'], ($, K, Utils) ->
    class
        constructor: (@container) ->

        cycle:
            variables: {}
            reg: [0, 0, 0, 0, 0, 0, 0, 0]
            cc: [false, false, false]

        # Represents the main stage and layer.
        mainStage = null
        mainLayer = null
        infoLayer = null
        # Represents the labels container.
        labels = {}
        # Represents the color use for painting.
        colors =
            white: 'white'
            black: 'black'
            blue: '#8ED8F8'
            red: 'red'

        K.Rect::rightX = ->
            @getX() + @getWidth()

        # Represents the basic label rectangle
        basicRect = new K.Rect
            width: 30
            height: 25
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
                height: 25
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
            stage.addRect 310, colors.blue
            return stage

        # Generate the decode stage
        decodeStage = (y) ->
            stage = new K.Group
                x: 20
                y: y
            stage.stageName = 'D'

            stage.addNameRect 30
            stage.addRect 30, colors.white, 'stat'
            stage.addRect 35, colors.white, 'icode'
            stage.addRect 35, colors.white, 'ifun'
            stage.addRect 30, colors.white, 'rA'
            stage.addRect 30, colors.white, 'rB'
            stage.addRect 70, colors.white, 'valC'
            stage.addRect 15, colors.blue
            stage.addRect 70, colors.white, 'valP'
            stage.addRect 115, colors.blue
            #stage.addRect 40, colors.white, 'pc'
            return stage

        # Generate the execute stage.
        executeStage = (y) ->
            stage = new K.Group
                x: 20
                y: y
            stage.stageName = 'E'

            stage.addNameRect 30
            stage.addRect 30, colors.white, 'stat'
            stage.addRect 35, colors.white, 'icode'
            stage.addRect 35, colors.white, 'ifun'
            stage.addRect 70, colors.white, 'valC'
            stage.addRect 70, colors.white, 'valA'
            stage.addRect 70, colors.white, 'valB'
            stage.addRect 30, colors.white, 'dstE'
            stage.addRect 30, colors.white, 'dstM'
            stage.addRect 30, colors.white, 'srcA'
            stage.addRect 30, colors.white, 'srcB'
            #stage.addRect 40, colors.white, 'pc'
            return stage

        # Generate the memory stage
        memoryStage = (y) ->
            stage = new K.Group
                x: 20
                y: y
            stage.stageName = 'M'

            stage.addNameRect 30
            stage.addRect 30, colors.white, 'stat'
            stage.addRect 35, colors.white, 'icode'
            stage.addRect 30, colors.blue
            stage.addRect 35, colors.white, 'Cnd'
            stage.addRect 20, colors.blue
            stage.addRect 70, colors.white, 'valE'
            stage.addRect 70, colors.white, 'valA'
            stage.addRect 20, colors.blue
            stage.addRect 30, colors.white, 'dstE'
            stage.addRect 30, colors.white, 'dstM'
            stage.addRect 60, colors.blue
            #stage.addRect 40, colors.white, 'pc'
            return stage

        # Generate the writeback stage.
        writebackStage = (y) ->
            stage = new K.Group
                x: 20
                y: y
            stage.stageName = 'W'

            stage.addNameRect 30
            stage.addRect 30, colors.white, 'stat'
            stage.addRect 35, colors.white, 'icode'
            stage.addRect 85, colors.blue
            stage.addRect 70, colors.white, 'valE'
            stage.addRect 70, colors.white, 'valM'
            stage.addRect 20, colors.blue
            stage.addRect 30, colors.white, 'dstE'
            stage.addRect 30, colors.white, 'dstM'
            stage.addRect 60, colors.blue
            #stage.addRect 40, colors.white, 'pc'
            return stage

        registerRects = []
        registerNames = ['%eax', '%ecx', '%edx', '%ebx', '%esp', '%ebp', '%esi', '%edi']
        registerTexts = []

        ccNames = ['ZF', 'SF', 'OF']
        ccTexts = []

        # Render the register the group
        registerGroup = (y) ->
            group = new K.Group
                x: 20
                y: y

            width = 70
            registerRects = []
            registerTexts = []
            for i in [0..7]
                rect = basicRect.clone
                    x: (i % 4) * width
                    y: Math.floor(i / 4) * 25
                    fill: colors.white
                    width: width
                text = new K.Text
                    fill: colors.black
                    fontFamily: 'Consolas'
                    fontSize: 11
                    align: 'center'
                    x: rect.getX()
                    width: width
                registerRects.push(rect)
                registerTexts.push(text)
                group.add(rect)
                group.add(text)
            width = 50
            ccTexts = []
            for i in [0..2]
                rect = basicRect.clone
                    x: i * width + 320
                    y: 10
                    fill: colors.white
                    width: width
                text = new K.Text
                    fill: colors.black
                    fontFamily: 'Consolas'
                    align: 'center'
                    fontSize: 11
                    x: rect.getX()
                    y: rect.getY()
                    width: width
                ccTexts.push(text)
                group.add(rect)
                group.add(text)
            return group

        # Render the whole container.
        render: ->
            scale = $(window).width() / 800.0
            mainStage = new K.Stage
                container: @container
                width: $(window).width() * 0.65
                height: 1000
                scale: scale

            infoLayer = new K.Layer()
            infoLayer.add new K.Text
                id: 'info'
                fontSize: 15
                fill: colors.blue
                padding: 10
                fontFamily: 'Consolas'
                shadowColor: colors.black
                shadowBlur: -1
                shadowOffset: 1
            mainStage.add(infoLayer)
            @f_render()

        renderMain: ->
            if mainLayer? then mainLayer.remove()
            infoLayer.hide()
            labels = {}
            mainLayer = new K.Layer()
            mainLayer.add fetchStage(270)
            mainLayer.add decodeStage(210)
            mainLayer.add executeStage(150)
            mainLayer.add memoryStage(90)
            mainLayer.add writebackStage(30)
            mainLayer.add registerGroup(330)
            mainStage.add(mainLayer)
            @show()

        basePath = 'assets/images/'

        # Generate a tooltip of value
        genTooltip: (x, y, height, width, id, len)->
            rect = new K.Rect
                id: id
#                fill: colors.red
                x: x
                y: y
                height: height
                width: width
                len: len
            that = @
            rect.on('mouseover', ->
                len = @getAttr('len')
                text = that.cycle.variables[@getId()]
                if len is -1
                    text = that.strToStat(text)
                else if len isnt 0
                    text = Utils.num2hex(text, len)
                text = @getId() + ' = ' + text
                infoLayer.get('#info')[0].setText(text)
                infoLayer.draw()
            )
            rect.on('mouseout', ->
                infoLayer.get('#info')[0].setText('')
                infoLayer.draw()
            )
            mainLayer.add(rect)

        # Add tooltips to f
        f_addTooltip: ->
            @genTooltip(75, 210, 45, 85, 'f_stat', -1)
            @genTooltip(5, 350, 75, 110, 'instr_valid', 0)
            @genTooltip(635, 285, 75, 110, 'need_valC', 0)
            @genTooltip(635, 390, 75, 110, 'need_regids', 0)
            @genTooltip(185, 525, 45, 85, 'f_icode', 1)
            @genTooltip(275, 525, 45, 85, 'f_ifun', 1)
            @genTooltip(300, 890, 165, 135, 'f_pc', 8)
            @genTooltip(1015, 185, 115, 135, 'f_predPC', 8)
            @genTooltip(1169, 0, 22, 92, 'M_icode', 1)
            @genTooltip(1201, 47, 22, 75, 'M_Cnd', 0)
            @genTooltip(1237, 92, 22, 81, 'M_valA', 8)
            @genTooltip(1271, 139, 22, 95, 'W_icode', 1)
            @genTooltip(1304, 184, 22, 88, 'W_valM', 8)
            @genTooltip(62, 773, 22, 127, 'imem_error', 0)

        # Generate a rectangle
        genRect: (x, y, width, prefix, name) ->
            text = new K.Text
                id: prefix + name
                name: name
                x: x
                y: y
                oldY: y
                width: width
                fontSize: 28
                fill: colors.black
                fontFamily: 'Consolas'
                align: 'center'
                text: name
            text.setY(text.getAttr('oldY') + (58 - text.getHeight()) / 2)
            mainLayer.add(text)

        #Add rectangles to f
        f_addRects: ->
            @genRect(96, 101, 85, 'D_', 'stat')
            @genRect(183, 101, 85, 'D_', 'icode')
            @genRect(272, 101, 85, 'D_', 'ifun')
            @genRect(361, 101, 85, 'D_', 'rA')
            @genRect(450, 101, 85, 'D_', 'rB')
            @genRect(539, 101, 175, 'D_', 'valC')
            @genRect(806, 101, 175, 'D_', 'valP')
            @genRect(278, 1111, 175, 'F_', 'predPC')

        genLine: (points, width, name, from) ->
            line = new K.Line
                name: name
                from: from
                points: points
                stroke: colors.red
                strokeWidth: 6
            mainLayer.add(line)

        f_addLines: ->
            @genLine([1245, 125, 1245, 977, 455, 977], 6, 'M_valA', 'f_pc_from')
            @genLine([1312, 215, 1312, 1029, 455, 1029], 6, 'W_valM', 'f_pc_from')
            @genLine([366, 1107, 366, 1075], 6, 'F_predPC', 'f_pc_from')

            @genLine([588, 595, 588, 239, 990, 239], 6, 'f_valC', 'f_predPC_from')
            @genLine([893, 308, 893, 282, 990, 282], 6, 'f_valP', 'f_predPC_from')

        # Render the f stage
        f_render: ->
            if mainLayer? then mainLayer.remove()
            infoLayer.show()
            image = new Image()
            that = @
            image.onload = ->
                scale = 800 / image.width * 0.55
                mainLayer = new K.Layer
                    x: 20
                    y: 20
                    scale: scale

                img = new K.Image
                    width: image.width
                    height: image.height
                    image: image
                mainLayer.add(img)

                that.f_addLines()
                that.f_addRects()
                that.f_addTooltip()
                mainStage.add(mainLayer)
                that.show()
            image.src = basePath + 'F-D.png'

        # Change the string into state
        strToStat: (str) ->
            switch str
                when 0 then 'BUB'
                when 1 then 'AOK'
                when 2 then 'HLT'
                when 3 then 'ADR'
                when 4 then 'INS'
                when 5 then 'PIP'
                else 'STAT'

        # Show all the infomation.
        show: (cycle) ->
            if cycle? then @cycle = cycle
            variables = @cycle.variables
            reg = @cycle.reg
            cc = @cycle.cc
            that = @

            deal = (text, name, value) ->
                if name is 'stat'
                    str = that.strToStat(value)
                    text.setText(str)
                    if str in ['AOK', 'STAT']
                        text.setFill(colors.black)
                    else if str is 'BUB'
                        text.setFill(colors.blue)
                    else
                        text.setFill(colors.red)
                else
                    if not value?
                        text.setText(name)
                    else
                        text.setText(name + '\n' + Utils.num2hex(value, Utils.lengthFromName(name)))

            if mainLayer.get("Image").length isnt 0
                # Not in main stage
                texts = mainLayer.get('Text')
                texts.each (text) ->
                    name = text.getName()
                    value = variables[text.getId()]
                    deal(text, name, value)
                    text.setY(text.getAttr('oldY') + (58 - text.getHeight()) / 2)
                lines = mainLayer.get('Line')
                lines.each (line) ->
                    name = line.getName()
                    value = variables[line.getAttr('from')]
                    if value is name
                        line.show()
                    else
                        line.hide()
            else
                for own key, label of labels
                    name = label.labelName
                    value = variables[key]
                    deal(label, name, value)
                    label.setY((25 - label.getHeight()) / 2)

                # Show reigister
                if registerTexts.length > 0
                    for i in [0..7]
                        label = registerTexts[i]
                        label.setText(registerNames[i] + '\n' + Utils.num2hex(reg[i], 8))
                        label.setFill(colors.black)
                        rect = registerRects[i]
                        rect.setFill(colors.white)
                        label.setY(rect.getY() + (25 - label.getHeight()) / 2)
                    renderDstBG = (dst) ->
                        if dst? and dst isnt 0xf
                            registerRects[dst].setFill(colors.blue)
                            #registerTexts[dst].setFill(colors.white)
                    renderDstBG(variables.W_dstE)
                    renderDstBG(variables.W_dstM)

                # Show condition codes
                if ccTexts.length > 0
                    for i in [0..2]
                        ccTexts[i].setText(ccNames[i] + ': ' + (cc[i] | 0))
                        ccTexts[i].setY(10 + (25 - ccTexts[i].getHeight()) / 2)
            mainLayer.draw()
