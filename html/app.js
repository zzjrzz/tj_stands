const app = Vue.createApp({
    data() {
        return {
            showRentMenu: false,
            showShopMenu: false,
            inventory: [],
            config: {},
            stand: {},
            rentData: {
                title: '',
                description: '',
                hours: 1,
                items: {}
            },
            cart: {},
            notification: {
                show: false,
                message: '',
                type: 'success',
                timeout: null
            },
            loading: false,
            isStandOwner: false,
        }
    },
    computed: {
        rentalCost() {
            return this.rentData.hours * (this.config.basePrice || 0)
        },
        isValidRental() {
            return this.rentData.title &&
                   this.rentData.description &&
                   this.rentData.hours >= this.config.minHours &&
                   this.rentData.hours <= this.config.maxHours &&
                   Object.keys(this.rentData.items).length > 0
        },
        cartTotal() {
            return Object.entries(this.cart).reduce((total, [name, quantity]) => {
                return total + (this.stand.items[name].price * quantity)
            }, 0)
        }
    },
    methods: {
        showNotification(message, type = 'success') {
            if (this.notification.timeout) {
                clearTimeout(this.notification.timeout)
            }
            
            this.notification = {
                show: true,
                message,
                type,
                timeout: setTimeout(() => {
                    this.notification.show = false
                }, 3000)
            }
        },
        
        getItemImage(name) {
            return `${this.config.imagesPath}/${name}.png`
        },
        
        getItemLabel(name) {
            if (this.stand.items && this.stand.items[name]) {
                return this.stand.items[name].label;
            }
            const item = this.inventory.find(i => i.name === name)
            return item ? item.label : name
        },
        
        getItemTotal(name) {
            return this.stand.items[name].price * (this.cart[name] || 0)
        },
        
        selectItem(item) {
            if (this.rentData.items[item.name]) {
                this.showNotification('Item already selected', 'error')
                return
            }
            
            const inventoryItem = this.inventory.find(i => i.name === item.name)
            if (!inventoryItem || inventoryItem.count <= 0) {
                this.showNotification('Not enough items in inventory', 'error')
                return
            }
            
            this.rentData.items[item.name] = {
                quantity: '', 
                price: '',
                maxQuantity: inventoryItem.count
            }
        },
        
        updateItemQuantity(itemName, quantity) {
            const item = this.rentData.items[itemName]
            if (!item) return
            
            const newQuantity = Math.max(1, Math.min(quantity, item.maxQuantity))
            if (newQuantity !== quantity) {
                this.showNotification(`Maximum quantity for this item is ${item.maxQuantity}`, 'error')
            }
            
            item.quantity = newQuantity
        },
        
        removeItem(name) {
            delete this.rentData.items[name]
        },
        
        async rentStand() {
            for (const [itemName, itemData] of Object.entries(this.rentData.items)) {
                if (!itemData.quantity || !itemData.price) {
                    this.showNotification('Please set quantity and price for all items', 'error')
                    return
                }
                
                const inventoryItem = this.inventory.find(i => i.name === itemName)
                if (!inventoryItem || inventoryItem.count < itemData.quantity) {
                    this.showNotification(`Not enough ${this.getItemLabel(itemName)} in inventory`, 'error')
                    return
                }
            }
            
            try {
                this.loading = true
                
                const rentPayload = {
                    title: this.rentData.title,
                    description: this.rentData.description,
                    hours: this.rentData.hours,
                    items: {}
                }

                for (const [name, data] of Object.entries(this.rentData.items)) {
                    rentPayload.items[name] = {
                        quantity: parseInt(data.quantity),
                        price: parseInt(data.price)
                    }
                }

                const response = await fetch(`https://${GetParentResourceName()}/rentStand`, {
                    method: 'POST',
                    body: JSON.stringify(rentPayload)
                })
                
                const result = await response.json()
                
                if (result.success) {
                    this.showNotification(result.message || 'Stand rented successfully')
                    setTimeout(() => this.closeMenu(), 0)
                } else {
                    this.showNotification(result.message || 'Failed to rent stand', 'error')
                }
            } catch (error) {
                this.showNotification('Failed to rent stand', 'error')
            } finally {
                this.loading = false
            }
        },
        
        async purchase(paymentMethod) {
            if (Object.keys(this.cart).length === 0) {
                this.showNotification('Cart is empty', 'error')
                return
            }
            
            try {
                this.loading = true
                let purchaseTimeout = setTimeout(() => {
                    this.loading = false
                    this.showNotification('Purchase request timed out', 'error')
                }, 2000)

                const response = await fetch(`https://${GetParentResourceName()}/purchaseItems`, {
                    method: 'POST',
                    body: JSON.stringify({
                        items: this.cart,
                        paymentMethod
                    })
                })
                
                clearTimeout(purchaseTimeout)
                const result = await response.json()
                
                if (result.success) {
                    this.showNotification(result.message)
                    for (const [itemName, quantity] of Object.entries(this.cart)) {
                        this.stand.items[itemName].quantity -= quantity
                    }
                    this.cart = {}
                    setTimeout(() => this.closeMenu(), 0)
                } else {
                    this.showNotification(result.message, 'error')
                }
            } catch (error) {
                this.showNotification('Failed to process purchase', 'error')
            } finally {
                this.loading = false
            }
        },
        
        addToCart(name, item) {
            if (!this.cart[name]) {
                this.cart[name] = 0
            }
            if (this.cart[name] < item.quantity) {
                this.cart[name]++
            } else {
                this.showNotification('Maximum quantity reached', 'error')
            }
        },
        
        updateCart(name, change) {
            const newQuantity = (this.cart[name] || 0) + change
            if (newQuantity <= 0) {
                delete this.cart[name]
            } else if (newQuantity <= this.stand.items[name].quantity) {
                this.cart[name] = newQuantity
            } else {
                this.showNotification('Not enough items in stock', 'error')
            }
        },
        
        closeMenu() {
            this.showRentMenu = false
            this.showShopMenu = false
            this.resetData()
            fetch(`https://${GetParentResourceName()}/closeUI`, {
                method: 'POST',
                body: JSON.stringify({})
            })
        },
        
        resetData() {
            this.rentData = {
                title: '',
                description: '',
                hours: 1,
                items: {}
            }
            this.cart = {}
        }
    },
    mounted() {
        window.addEventListener('message', (event) => {
            const data = event.data
            
            switch (data.action) {
                case 'openRent':
                    this.inventory = data.inventory
                    this.config = data.config
                    this.showRentMenu = true
                    this.showShopMenu = false
                    break
                    
                case 'openShop':
                    this.stand = data.stand
                    this.config = data.config
                    this.isStandOwner = data.isOwner
                    this.showShopMenu = true
                    this.showRentMenu = false
                    break
            }
        })
        
        window.addEventListener('keyup', (e) => {
            if (e.key === 'Escape') {
                this.closeMenu()
            }
        })
    }
}).mount('#app')