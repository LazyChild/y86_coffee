# The pipeline follows the CSAPP:2nd edition
define ['./Utils'], (Utils) ->
    class
        enviroment =
            reg: [0, 0, 0, 0, 0, 0, 0, 0]
            memory: []
            variables: {}
            cc: [0, 0, 0]
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
        sname = {}

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

        F_NONE      = 0

        REG_EAX     = 0x0;      rname[REG_EAX] = '%eax'
        REG_ECX     = 0x1;      rname[REG_ECX] = '%ecx'
        REG_EDX     = 0x2;      rname[REG_EDX] = '%edx'
        REG_EBX     = 0x3;      rname[REG_EBX] = '%ebx'
        REG_ESP     = 0x4;      rname[REG_ESP] = '%esp'
        REG_EBP     = 0x5;      rname[REG_EBP] = '%ebp'
        REG_ESI     = 0x6;      rname[REG_ESI] = '%esi'
        REG_EDI     = 0x7;      rname[REG_EDI] = '%edi'
        REG_NONE    = 0xf;      rname[REG_NONE] = '----'

        P_LOAD      = 0
        P_STALL     = 1
        P_BUBBLE    = 2
        P_ERROR     = 3

        STAT_BUB    = 0;        sname[STAT_BUB] = 'BUB'
        STAT_AOK    = 1;        sname[STAT_AOK] = 'AOK'
        STAT_HLT    = 2;        sname[STAT_HLT] = 'HLT'
        STAT_ADR    = 3;        sname[STAT_ADR] = 'ADR'
        STAT_INS    = 4;        sname[STAT_INS] = 'INS'
        STAT_PIP    = 5;        sname[STAT_PIP] = 'PIP'

        fetchPipe =
            op: P_LOAD
            elements:   ['F_predPC']
            from:       ['f_predPC']
        decodePipe =
            op: P_BUBBLE
            elements:   ['D_icode', 'D_ifun', 'D_rA', 'D_rB', 'D_valC', 'D_valP', 'D_stat']
            from:       ['f_icode', 'f_ifun', 'f_rA', 'f_rB', 'f_valC', 'f_valP', 'f_stat']
            bubble:     [I_NOP, F_NONE, REG_NONE, REG_NONE, 0, 0, STAT_BUB]
        executePipe =
            op: P_BUBBLE
            elements:   ['E_icode', 'E_ifun', 'E_valC', 'E_valA', 'E_valB', 'E_dstE', 'E_dstM', 'E_srcA', 'E_srcB', 'E_stat']
            from:       ['D_icode', 'D_ifun', 'D_valC', 'd_valA', 'd_valB', 'd_dstE', 'd_dstM', 'd_srcA', 'd_srcB', 'D_stat']
            bubble:     [I_NOP, F_NONE, 0, 0, 0, REG_NONE, REG_NONE, REG_NONE, REG_NONE, STAT_BUB]
        memoryPipe =
            op: P_BUBBLE
            elements:   ['M_icode', 'M_Cnd', 'M_valE', 'M_valA', 'M_dstE', 'M_dstM', 'M_stat']
            from:       ['E_icode', 'e_Cnd', 'e_valE', 'E_valA', 'e_dstE', 'E_dstM', 'E_stat']
            bubble:     [I_NOP, false, 0, 0, REG_NONE, REG_NONE, STAT_BUB]
        writebackPipe =
            op: P_BUBBLE
            elements:   ['W_icode', 'W_valE', 'W_valM', 'W_dstE', 'W_dstM', 'W_stat']
            from:       ['M_icode', 'M_valE', 'm_valM', 'M_dstE', 'M_dstM', 'm_stat']
            bubble:     [I_NOP, 0, 0, REG_NONE, REG_NONE, STAT_BUB]

        n2h = Utils.num2hex
        hpack = Utils.hexPack

        doReport: (cycle) ->
            now = @cycles[cycle]
            v = now.variables
            [ZF, SF, OF] = now.cc
            @report.push "Cycle #{n}. CC=Z=#{ZF} S=#{SF} O=#{OF}, STAT=#{sname[status]}"
            @report.push "F: predPC = #{n2h(v.F_predPC)}"
            @report.push "D: instr = #{iname[hpack(v.D_icode, v.D_ifun)]}, rA = #{rname[v.D_rA]}, rB = #{rname[v.D_rB]}, valC = #{n2h(v.D_valC, -1)}, Stat = #{sname[v.D_stat]}"
            @report.push "E: instr = #{iname[hpack(v.E_icode, v.E_ifun)]}, valC = #{n2h(v.E_valC, -1)}, valA = #{n2h(v.E_valA, -1)}, valB = #{n2h(v.E_valB, -1)}"
            @report.push "   srcA = #{rname[v.E_srcA]}, srcB = #{rname[v.E_srcB]}, dstE = #{rname[v.E_dstE]}, dstM = #{rname[v.E_dstM]}, Stat = #{sname[v.E_stat]}"
            @report.push "M: instr = #{iname[hpack(v.M_icode, v.M_ifun)]}, Cnd = #{v.M_Bch}, valE = #{n2h(v.M_valE, -1)}, valA = #{n2h(v.M_valA, -1)}"
            @report.push "   dstE = #{rname[v.M_dstE]}, dstM = #{rname[v.M_dstM]}, Stat = #{sname[v.M_stat]}"
            @report.push "W: instr = #{iname[hpack(v.W_icode, v.W_ifun)]}, valE = #{n2h(v.W_valE, -1)}, valM = #{n2h(v.W_valM, -1)}, dstE = #{rname[v.W_dstE]}, dstM = #{rname[v.W_dstM]}, Stat = #{sname[v.W_stat]}"
            @report.push ""

        performStep: ->
            n = @cycles.length
            prev = @cycles[n - 1]
            @cycles[n] = Utils.gen(prev)
            now = @cycles[n]
            v = now.variables

            status = 0

            load = (pipe) ->
                for i in [0, pipe.elements - 1]
                    v[pipe.elements[i]] = prev.variables[pipe.from[i]]
            stall = (pipe) ->
                for key in pipe.elements
                    v[key] = prev.variables[key]
            bubble = (pipe) ->
                for i in [0, pipe.elements - 1]
                    v[pipe.elements[i]] = pipe.bubble[i]

            updatePipe =(pipe) ->
                # 'LOAD' then load new value, 'STALL' then keep old value, 'BUBBLE' then no value
                switch pipe.status
                    when P_LOAD then load(pipe)
                    when P_STALL then stall(pipe)
                    when P_BUBBLE then bubble(pipe)
                    when P_ERROR then bubble(pipe)

            ################################### Perform the fetch stage ######################################
            doFetchStage = ->
                updatePipe fetchPipe

                # Get f_pc
                v.f_pc =
                    if v.M_icode is I_JXX and not v.M_Cnd then v.M_valA
                    else if v.W_icode is I_RET then v.W_valM
                    else v.F_predPC
                v.f_valP = v.f_pc

                imem_error = false

                # Fetch the memory
                instr = now.memory[v.f_valP++]
                imem_error |= not instr?
                v.f_icode =
                    if imem_error then I_NOP
                    else Utils.high4(instr[0])
                v.f_ifun =
                    if imem_error then F_NONE
                    else Utils.low4(instr[0])

                # Whether need register ids
                need_regids =
                    v.f_icode in [I_RRMOVL, I_OPL, I_PUSHL, I_POPL, I_IRMOVL, I_RMMOVL, I_MRMOVL]
                if need_regids
                    regids = now.memory[v.f_valP++]
                    imem_error |= not regids?
                    v.f_rA = Utils.high4(regids)
                    v.f_rB = Utils.low4(regids)
                else
                    v.f_rA = REG_NONE
                    v.f_rB = REG_NONE

                # Whether need valC
                need_valC =
                    v.f_icode in [I_IRMOVL, I_RMMOVL, I_MRMOVL, I_JXX, I_CALL]
                if need_valC
                    v.f_valC = Utils.getWord(now.memory, v.f_valP)
                    imem_error |= not now.memory[v.f_valP + 3]?
                    v.f_valP += 4

                v.f_predC =
                    if v.f_icode in [I_JXX, I_CALL] then v.f_valC
                    else v.f_valP

                instr_valid =
                    v.f_icode in [I_NOP, I_HALT, I_RRMOVL, I_IRMOVL, I_MRMOVL, I_OPL, I_JXX, I_CALL, I_RET, I_PUSHL, I_POPL]

                v.f_stat =
                    if imem_error then STAT_ADR
                    else if not instr_valid then STAT_INS
                    else if v.f_icode is I_HALT then STAT_HLT
                    else STAT_AOK

            ########################### Perform the decode and writeback stage ################################
            doDecodeAndWriteStage = ->
                updatePipe decodePipe
                updatePipe writebackPipe

                v.d_srcA =
                    if v.D_icode in [I_RRMOVL, I_RMMOVL, I_OPL, I_PUSHL] then v.D_rA
                    else if v.D_icode in [I_POPL, I_RET] then REG_ESP
                    else REG_NONE

                v.d_srcB =
                    if v.D_icode in [I_OPL, I_RMMOVL, I_MRMOVL] then v.D_rB
                    else if v.D_icode in [I_PUSHL, I_POPL, I_CALL, I_RET] then REG_ESP
                    else REG_NONE

                v.d_dstE =
                    if v.D_icode in [I_RRMOVL, I_IRMOVL, I_OPL] then v.D_rB
                    else if v.D_icode in [I_PUSHL, I_POPL, I_CALL, I_RET] then REG_ESP
                    else REG_NONE

                v.d_dstM =
                    if v.D_icode in [I_MRMOVL, I_POPL] then v.D_rA
                    else REG_NONE

                # Read value A from register file
                d_rvalA = now.reg[v.d_srcA]
                d_rvalB = now.reg[v.d_srcB]

                v.d_valA =
                    if v.D_icode in [I_CALL, I_JXX] then v.D_valP
                    else if v.d_srcA is v.e_dstE then v.e_valE
                    else if v.d_srcA is v.M_dstM then v.m_valM
                    else if v.d_srcA is v.M_dstE then v.M_valE
                    else if v.d_srcA is v.W_dstM then v.W_valM
                    else if v.d_srcA is v.W_dstE then v.W_valE
                    else d_rvalA

                v.d_valB =
                    if v.d_srcB is v.e_dstE then v.e_valE
                    else if v.d_srcB is v.M_dstM then v.m_valM
                    else if v.d_srcB is v.M_dstE then v.M_valE
                    else if v.d_srcB is v.W_dstM then v.W_valM
                    else if v.d_srcB is v.W_dstE then v.W_valE
                    else d_rvalB

                # Write back
                now.reg[v.M_dstE] = v.M_valE
                now.reg[v.M_dstM] = v.M_valM

                status =
                    if v.W_stat is STAT_BUB then STAT_AOK
                    else v.W_stat

            ################################### Perform the execute stage #####################################
            doExecuteStage = ->
                updatePipe executePipe

                # Get the alu value A
                aluA =
                    if v.E_icode in [I_RRMOVL, I_OPL] then v.E_valA
                    else if v.E_icode in [I_IRMOVL, I_RMMOVL, I_MRMOVL] then v.E_valC
                    else if v.E_icode in [I_CALL, I_PUSHL] then -4
                    else if v.E_icode in [I_RET, I_POPL] then 4

                # Get the alu value B
                aluB =
                    if v.E_icode in [I_RMMOVL, I_MRMOVL, I_OPL, I_CALL, I_PUSHL, I_RET, I_POPL] then v.E_valB
                    else if v.E_icode in [I_RRMOVL, I_IRMOVL] then 0

                # Get the alu function
                alufun =
                    if v.E_icode is I_OPL then v.E_ifun
                    else ALU_ADD

                i = (v) -> v | 0

                # Compute the alu value.
                compute_alu = (aluA, aluB, alufun) ->
                    switch alufun
                        when ALU_ADD then i(aluA + aluB)
                        when ALU_SUB then i(aluA - aluB)
                        when ALU_AND then aluA & aluB
                        when ALU_XOR then aluA ^ aluB

                v.e_valE = compute_alu(aluA, aluB, alufun)

                # Compute the condition code.
                compute_cc = (aluA, aluB, alufun) ->
                    val = compute_alu(aluA, aluB, alufun)
                    ZF = val is 0
                    SF = i(val) < 0
                    gen_of = ->
                        sign = (v) -> i(v) < 0
                        switch alufun
                            when ALU_ADD
                                (sign(aluA) is sign(aluB)) and (sign(val) isnt sign(aluB))
                            when ALU_SUB
                                (sign(aluA) isnt sign(aluB)) and (sign(val) isnt sign(aluB))
                            else false
                    OF = gen_of()
                    [ZF, SF, OF]

                set_cc =
                    (v.E_icode is I_OPL) and not(v.m_stat in [STAT_ADR, STAT_INS, STAT_HLT]) and not(v.W_stat in [STAT_ADR, STAT_INS, STAT_HLT])
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

                    v.e_Cnd = hold_condition(now.cc, v.E_ifun)

                v.e_valA =
                    v.E_valA
                v.e_dstE =
                    if v.E_icode is I_RRMOVL and not v.e_Cnd then REG_NONE
                    else v.E_dstE

            ################################## Perform the memory stage #######################################
            doMemoryStage = ->
                updatePipe memoryPipe

                dmem_error = false

                mem_addr =
                    if v.M_icode in [I_RMMOVL, I_PUSHL, I_CALL, I_MRMOVL] then v.M_valE
                    else if v.M_icode in [I_POPL, I_RET] then v.M_valA

                # Read memory
                mem_read =
                    v.M_icode in [I_MRMOVL, I_POPL, I_RET]
                if mem_read
                    v.m_valM = Utils.getWord(now.memory, mem_addr)
                    dmem_error |= not now.memory[mem_addr + 3]?

                # Write memory
                mem_write =
                    v.M_icode in [I_RMMOVL, I_PUSHL, I_CALL]
                mem_data = v.M_valA
                if mem_write
                    Utils.setWord(now.memory, mem_addr, mem_data)
                    dmem_error |= not now.memory[mem_addr + 3]?

                v.m_stat =
                    if dmem_error then STAT_ADR
                    else v.M_stat

            ############################### Perform stall and bubble check ####################################
            checkStageOp = ->
                pipe_control = (name, stall, bubble) ->
                    if stall
                        if bubble then P_ERROR
                        else P_STALL
                    else if bubble then P_BUBBLE
                    else P_LOAD

                load_use_hazard =
                    v.E_icode in [I_MRMOVL, I_POPL] and v.E_dstM in [v.d_srcA, v.d_srcB]
                ret_pass_through =
                    I_RET in [v.D_icode, v.E_icode, v.M_icode]
                mispredicted_branch =
                    v.E_icode is I_JXX and not v.e_Cnd

                F_stall =
                    load_use_hazard or ret_pass_through
                F_bubble = 0
                fetchPipe.op = pipe_control("fetch", F_stall, F_bubble)

                D_stall =
                    load_use_hazard
                D_bubble =
                    mispredicted_branch or (not load_use_hazard and ret_pass_through)
                decodePipe.op = pipe_control("decode", D_stall, D_bubble)

                E_stall = 0
                E_bubble =
                    mispredicted_branch or load_use_hazard
                executePipe.op = pipe_control("execute", E_stall, E_bubble)

                M_stall = 0
                M_bubble =
                    v.m_stat in [STAT_ADR, STAT_INS, STAT_HLT] or v.W_stat in [STAT_ADR, STAT_INS, STAT_HLT]
                memoryPipe.op = pipe_control("memory", M_stall, M_bubble)

                W_stall =
                    v.W_stat in [STAT_ADR, STAT_INS, STAT_HLT]
                W_bubble = 0
                writebackPipe.op = pipe_control("write-back", W_stall, W_bubble)

            ### main perform step ###
            if fetchPipe.op is P_ERROR
                v.F_stat = STAT_PIP
            if decodePipe.op is P_ERROR
                v.D_stat = STAT_PIP
            if executePipe.op is P_ERROR
                v.E_stat = STAT_PIP
            if memoryPipe.op is P_ERROR
                v.M_stat = STAT_PIP
            if writebackPipe.op is P_ERROR
                v.W_stat = STAT_PIP

            doFetchStage()
            doExecuteStage()
            doMemoryStage()
            doDecodeAndWriteStage()

            checkStageOp()

            @doReport(n)

        run: ->
            icount = 0
            ccount = 0
            loop
                run_stat = @performStep()
                ++icount if run_stat isnt STAT_BUB
                ++ccount
                break if run_stat isnt STAT_AOK and run_stat isnt STAT_BUB