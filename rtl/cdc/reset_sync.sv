/* 
    Standard Reset Pattern:
        Async assert    (Can happen immediately)
        Sync deassert   (Release in clock domain safely)

    async_rst -> FF1 -> FF2 -> sync_rst
*/

