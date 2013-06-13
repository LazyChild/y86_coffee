define ['./Utils'], (Utils) ->
    class
        enviroment =
            reg: [0, 0, 0, 0, 0, 0, 0, 0]
            memory: []
            variables: {}
            cc: []
        # Load the *.yo file from the text.
        constructor: (text) ->
            lines = text.split '\n'
            @cycles[0] = Utils.gen enviroment
            for line in lines
                part = line.trim().split '|'
                if part.length isnt 2 then return null

                if part[0] is '' then continue
                words = part[0].trim().split /:\s?/
                if words.length isnt 2 then return null
                if words[1] is '' then continue

                address = Utils.hex2num words[0]
                for i in [0..words[1].length - 1] by 2
                    @cycles[0].memory[address++] = Utils.hex2num words[1][i] + words[1][i + 1]
            @

        # Represents the cycles.
        cycles: []

        # Represents the report.
        report: []

        iname = {}
        rname = {}

        # Represents the value
        I_NOP       = 0x0;      iname[I_NOP     << 4]           = 'nop'
        I_HALT      = 0x1;      iname[I_HALT    << 4]           = 'halt'
        I_RRMOVL    = 0x2;      iname[I_RRMOVL  << 4]           = 'rrmovl'
        I_IRMOVL    = 0x3;      iname[I_IRMOVL  << 4]           = 'irmovl'
        I_RMMOVL    = 0x4;      iname[I_RMMOVL  << 4]           = 'rmmovl'
        I_MRMOVL    = 0x5;      iname[I_MRMOVL  << 4]           = 'mrmovl'

        I_OPL       = 0x6
        # ALU functions
        ALU_ADD     = 0x0;      iname[(I_OPL << 4) + ALU_ADD]   = 'addl'
        ALU_SUB     = 0x1;      iname[(I_OPL << 4) + ALU_SUB]   = 'subl'
        ALU_AND     = 0x2;      iname[(I_OPL << 4) + ALU_AND]   = 'andl'
        ALU_XOR     = 0x3;      iname[(I_OPL << 4) + ALU_XOR]   = 'xorl'

        I_JXX       = 0x7
        # Jumps
        J_YES       = 0x0;      iname[(I_JXX << 4) + J_YES]     = 'jmp'
        J_LE        = 0x1;      iname[(I_JXX << 4) + J_LE]      = 'jle'
        J_L         = 0x2;      iname[(I_JXX << 4) + J_L]       = 'jl'
        J_E         = 0x3;      iname[(I_JXX << 4) + J_E]       = 'je'
        J_NE        = 0x4;      iname[(I_JXX << 4) + J_NE]      = 'jne'
        J_GE        = 0x5;      iname[(I_JXX << 4) + J_GE]      = 'jge'
        J_G         = 0x6;      iname[(I_JXX << 4) + J_G]       = 'jg'

        I_CALL      = 0x8;      iname[I_CALL    << 4]           = 'call'
        I_RET       = 0x9;      iname[I_RET     << 4]           = 'ret'
        I_PUSHL     = 0xa;      iname[I_PUSHL   << 4]           = 'pushl'
        I_POPL      = 0xb;      iname[I_POPL    << 4]           = 'popl'

        REG_EAX     = 0x0;      rname[REG_EAX] = '%eax'
        REG_ECX     = 0x1;      rname[REG_ECX] = '%ecx'
        REG_EDX     = 0x2;      rname[REG_EDX] = '%edx'
        REG_EBX     = 0x3;      rname[REG_EBX] = '%ebx'
        REG_ESP     = 0x4;      rname[REG_ESP] = '%esp'
        REG_EBP     = 0x5;      rname[REG_EBP] = '%ebp'
        REG_ESI     = 0x6;      rname[REG_ESI] = '%esi'
        REG_EDI     = 0x7;      rname[REG_EDI] = '%edi'
        REG_NONE    = 0x8;      rname[REG_NONE] = '----'

        P_LOAD      = 0
        P_STALL     = 1
        P_BUBBLE    = 2
        P_ERROR     = 3

        fetchPipe =
            op: P_LOAD
            elements: ['F_predPC']
            from: ['new_F_predPC']
        decodePipe =
            op: P_LOAD
            elements: ['D_icode', 'D_ifun', 'D_rA', 'D_rB', 'D_valC', 'D_valP']
            from: ['f_icode', 'f_ifun', 'f_rA', 'f_rB', 'f_valC', 'f_valP']
        executePipe =
            op: P_LOAD
            elements: ['E_icode', 'E_ifun', 'E_valC', 'E_valA', 'E_valB', 'E_dstE', 'E_dstM', 'E_srcA', 'E_srcB']
            from: ['D_icode', 'D_ifun', 'D_valC', 'new_E_valA', 'new_E_valB', 'new_E_dstE', 'new_E_dstM', 'd_srcA', 'd_srcB']
        memoryPipe =
            op: P_LOAD
            elements: ['M_icode', 'M_Bch', 'M_valE', 'M_valA', 'M_dstE', 'M_dstM']
            from: ['E_icode', 'e_Bch', 'e_valE', 'E_valA', 'E_dstE', 'E_dstM']
        writebackPipe =
            op: P_LOAD
            elements: ['W_icode', 'W_valE', 'W_valM', 'W_dstE', 'W_dstM']
            from: ['M_icode', 'M_valE', 'm_valM', 'M_dstE', 'M_dstM']

        STAT_AOK = 0
        STAT_BUB = 1

        n2h = Utils.num2hex
        hpack = Utils.hexPack

        performStep = ->
            n = @cycles.length
            prev = @cycles[n - 1]
            @cycles[n] = prev.gen()
            now = @cycles[n]
            v = now.variables

            status = 0

            load = (pipe) ->
                for i in [0, pipe.elements - 1]
                    v[pipe.elements[i]] = prev.variables[pipe.from[i]]
            stall = (pipe) ->
                for v in pipe.elements
                    v[key] = prev.variables[key]
            bubble = (pipe) ->
                # Do nothing

            updatePipe =(pipe) ->
                # 'LOAD' then load new value, 'STALL' then keep old value, 'BUBBLE' then no value
                switch pipe.status
                    when P_LOAD then load(pipe)
                    when P_STALL then stall(pipe)
                    when P_BUBBLE then bubble(pipe)

            doReport = ->
                [ZF, SF, OF] = now.cc
                cc_str = "Z=#{ZF} S=#{SF} O=#{OF}"
                @report.add "Cycle #{n}. CC=#{cc_str}, STAT=#{now.status}"
                @report.add "F: predPC = #{n2h(v.F_predPC)}"
                @report.add "D: instr = #{iname[hpack(v.D_icode, v.D_ifun)]}, rA = #{rname[v.D_rA]}, rB = #{rname[v.D_rB]}, valC = #{n2h(v.D_valC, -1)}, Stat = #{v.D_stat}"
                @report.add "E: instr = #{iname[hpack(v.E_icode, v.E_ifun)]}, valC = #{n2h(v.E_valC, -1)}, valA = #{n2h(v.E_valA, -1)}, valB = #{n2h(v.E_valB, -1)}"
                @report.add "   srcA = #{rname[v.E_srcA]}, srcB = #{rname[v.E_srcB]}, dstE = #{rname[v.E_dstE]}, dstM = #{rname[v.E_dstM]}, Stat = #{v.E_stat}"
                @report.add "M: instr = #{iname[hpack(v.M_icode, v.M_ifun)]}, Cnd = #{v.M_Bch}, valE = #{n2h(v.M_valE, -1)}, valA = #{n2h(v.M_valA, -1)}"
                @report.add "   dstE = #{rname[v.M_dstE]}, dstM = #{rname[v.M_dstM]}, Stat = #{v.M_stat}"
                @report.add "W: instr = #{iname[hpack(v.W_icode, v.W_ifun)]}, valE = #{n2h(v.W_valE, -1)}, valM = #{n2h(v.W_valM, -1)}, dstE = #{rname[v.W_dstE]}, dstM = #{rname[v.W_dstM]}, Stat = #{v.W_stat}"
                @report.add ""

            ################################### Perform the fetch stage ######################################
            doFetchStage = ->
                updatePipe fetchPipe

                # Get f_pc
                v.f_pc =
                    if v.M_icode is I_JXX and not v.M_Bch
                        v.M_valA
                    else if v.W_icode == I_RET
                        v.W_valM
                    else
                        v.F_predPC
                v.f_valP = v.f_pc

                # Fetch the memory
                instr = now.memory[v.f_valP++]
                v.f_icode = Utils.high4(instr[0])
                v.f_ifun  = Utils.low4(instr[0])

                instr_valid =
                    v.f_icode in [I_NOP, I_HALT, I_RRMOVL, I_IRMOVL, I_MRMOVL, I_OPL, I_JXX, I_CALL, I_RET, I_PUSHL, I_POPL]

                if instr_valid
                    console.log 'Fetch: Instruction code ' + Utils.num2hex(instr) + 'invalid'

                need_regids =
                    v.f_icode in [I_RRMOVL, I_OPL, I_PUSHL, I_POPL, I_IRMOVL, I_RMMOVL, I_MRMOVL]

                need_valC =
                    v.f_icode in [I_IRMOVL, I_RMMOVL, I_MRMOVL, I_JXX, I_CALL]

                if need_regids
                    regids = now.memory[v.f_valP++]
                    v.f_rA = Utils.high4(regids)
                    v.f_rB = Utils.low4(regids)
                else
                    v.f_rA = REG_NONE
                    v.f_rB = REG_NONE

                if need_valC
                    v.f_valC = Utils.getWord(now.memory, v.f_valP)
                    v.f_valP += 4

                v.new_F_predC =
                    if v.f_icode in [I_JXX, I_CALL]
                        v.f_valC
                    else
                        v.f_valP

            ########################### Perform the decode and writeback stage ################################
            doDecodeAndWriteStage = ->
                updatePipe decodePipe
                updatePipe writebackPipe

                # status = gen_stat()

                v.d_srcA =
                    if v.D_icode in [I_RRMOVL, I_RMMOVL, I_OPL, I_PUSHL]
                        v.D_rA
                    else if v.D_icode in [I_POPL, I_RET]
                        REG_ESP
                    else
                        REG_NONE

                v.d_srcB =
                    if v.D_icode in [I_OPL, I_RMMOVL, I_MRMOVL]
                        v.D_rB
                    else if v.D_icode in [I_PUSHL, I_POPL, I_CALL, I_RET]
                        REG_ESP
                    else
                        REG_NONE

                v.new_E_dstE =
                    if v.D_icode in [I_RRMOVL, I_RMMOVL, I_OPL]
                        v.D_rB
                    else if v.D_icode in [I_PUSHL, I_POPL, I_CALL, I_RET]
                        REG_ESP
                    else
                        REG_NONE

                v.new_E_dstM =
                    if v.D_icode in [I_MRMOVL, I_POPL]
                        v.D_rA
                    else
                        REG_NONE

                # Read value A from register file
                d_rvalA = now.reg[v.d_srcA]
                d_rvalB = now.reg[v.d_srcB]

                v.new_E_valA =
                    if v.D_icode in [I_CALL, I_JXX]
                        v.D_valP
                    else if v.d_srcA is v.E_dstE
                        v.e_valE
                    else if v.d_srcA is v.M_dstM
                        v.m_valM
                    else if v.d_srcA is v.M_dstE
                        v.M_valE
                    else if v.d_srcA is v.W_dstM
                        v.W_valM
                    else if v.d_srcA is v.W_dstE
                        v.W_valE
                    else
                        d_rvalA

                v.new_E_valB =
                    if v.d_srcB is v.E_dstE
                        v.e_valE
                    else if v.d_srcB is v.M_dstM
                        v.m_valM
                    else if v.d_srcB is v.M_dstE
                        v.M_valE
                    else if v.d_srcB is v.W_dstM
                        v.W_valM
                    else if v.d_srcB is v.W_dstE
                        v.W_valE
                    else
                        d_rvalB

                # Write back
                now.reg[v.M_dstE] = v.M_valE
                now.reg[v.M_dstM] = v.M_valM

            ################################### Perform the execute stage #####################################
            doExecuteStage = ->
                updatePipe executePipe

                # Get the alu value A
                aluA =
                    if v.E_icode in [I_RRMOVL, I_OPL]
                        v.E_valA
                    else if v.E_icode in [I_IRMOVL, I_RMMOVL, I_MRMOVL]
                        v.E_valC
                    else if v.E_icode in [I_CALL, I_PUSHL]
                        -4
                    else if v.E_icode in [I_RET, I_POPL]
                        4

                # Get the alu value B
                aluB =
                    if v.E_icode in [I_RMMOVL, I_MRMOVL, I_OPL, I_CALL, I_PUSHL, I_RET, I_POPL]
                        v.E_valB
                    else if v.E_icode in [I_RRMOVL, I_IRMOVL]
                        0

                # Get the alu function
                alufun =
                    if v.E_icode is I_OPL
                        v.E_ifun
                    else
                        ALU_ADD

                int = (v) -> v | 0

                # Compute the alu value.
                compute_alu = (aluA, aluB, alufun) ->
                    switch alufun
                        when ALU_ADD then int(aluA + aluB)
                        when ALU_SUB then int(aluA - aluB)
                        when ALU_AND then aluA & aluB
                        when ALU_XOR then aluA ^ aluB

                v.e_valE = compute_alu aluA, aluB, alufun

                # Compute the condition code.
                compute_cc = (aluA, aluB, alufun) ->
                    val = compute_alu(aluA, aluB, alufun)
                    ZF = val is 0
                    SF = int(val) < 0
                    gen_of = ->
                        sign = (v) -> int(v) < 0
                        switch alufun
                            when ALU_ADD
                                (sign(aluA) is sign(aluB)) and (sign(val) isnt sign(aluB))
                            when ALU_SUB
                                (sign(aluA) isnt sign(aluB)) and (sign(val) isnt sign(aluB))
                            else false
                    OF = gen_of()
                    [ZF, SF, OF]

                set_cc = v.E_icode is I_OPL
                if set_cc
                    now.cc = compute_cc(aluA, aluB, alufun)
                    hold_condition = (cc, ifun) ->
                        [ZF, SF, OF] = cc
                        switch ifun
                            when J_YES then true
                            when J_LE then (SF ^ OF) | ZF
                            when J_L then SF ^ OF
                            when J_E then ZF
                            when J_NE then ZF ^ 1
                            when J_GE then SF ^ OF ^ 1
                            when J_G then (SF ^ OF ^ 1) & (ZF ^ 1)
                            else false

                    v.e_Bch = hold_condition(now.cc, v.E_ifun)

            ################################## Perform the memory stage #######################################
            doMemoryStage = ->
                updatePipe memoryPipe

                mem_addr =
                    if v.M_icode in [I_RMMOVL, I_PUSHL, I_CALL, I_MRMOVL]
                        v.M_valE
                    else if v.M_icode in [I_POPL, I_RET]
                        v.M_valA

                # Read memory
                mem_read = v.M_icode in [I_MRMOVL, I_POPL, I_RET]
                v.m_valM = Utils.getWord(now.memory, mem_addr) if mem_read

                # Write memory
                mem_write = v.M_icode in [I_RMMOVL, I_PUSHL, I_CALL]
                mem_data = v.M_valA
                Utils.setWord(now.memory, mem_addr, mem_data) if mem_write

            ############################### Perform stall and bubble check ####################################
            checkStageOp = ->
                F_stall = (v.E_icode in [I_MRMOVL, I_POPL] and v.E_dstM in [v.d_srcA, v.d_srcB]) or (I_RET in [v.D_icode, v.E_icode, v.M_icode])
                F_bubble = 0
                fetchPipe.op = pipe_control("fetch", F_stall, F_bubble)

                D_stall = v.E_icode in [I_MRMOVL, I_POPL] and v.E_dstM in [v.d_srcA, v.d_srcB]
                D_bubble = (v.E_icode is I_JXX and not v.e_Bch) or (I_RET in [v.D_icode, v.E_icode, v.M_icode])
                decodePipe.op = pipe_control("decode", D_stall, D_bubble)

                E_stall = 0
                E_bubble = (v.E_icode is I_JXX and not v.e_Bch) or (v.E_icode in [I_MRMOVL, I_POPL] and v.E_dstM in [v.d_srcA, v.d_srcB])
                executePipe.op = pipe_control("execute", E_stall, E_bubble)


            ### main perform step ###
            doFetchStage()
            doExecuteStage()
            doMemoryStage()
            doDecodeAndWriteStage()

            checkStageOp()

        run: ->
            loop
                result = performStep()
            break if result isnt STAT_AOK and result isnt STAT_BUB
