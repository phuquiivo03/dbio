module dbio::dbio {
    use sui::coin::{Coin, Self, TreasuryCap};
    use sui::tx_context::{TxContext, Self};
    use sui::object::{UID};
    use sui::transfer;
    use sui::url::{Self, Url};
    use sui::balance::{Self, Balance};
    use std::string::{String};
    use sui::dynamic_object_field as dof;
    use sui::package;
    use sui::display;
    use sui::event;

    const EUserNotExist: u64 = 0;
    const EUserExist: u64 = 1;
    const EComponentNotExist: u64 = 2;
    
    public struct GetDataEvent has copy, drop {
        id: ID,
        components: vector<ID>,
    }

    public struct DeleteComponentEvent has copy, drop  {
        id: ID
    }

    public struct Component has key, store {
        id: UID,
        name: String,
        description: String,
        image_url: String,
        link: String,
        is_active: bool
    }

    public struct User has key, store {
        id: UID,
        components: vector<ID>,
        total_component: u64
    }

    public struct DBioApp has key {
        id: UID,
        total_user: u64
    }

    public struct DBIO has drop {}

    fun init(
        otw: DBIO, 
        ctx: &mut TxContext
    ) {
        let publisher = package::claim(otw, ctx);
        
        let keys = vector[
            b"name".to_string(),
            b"description".to_string(),
            b"image_url".to_string(),
            b"link".to_string(),
            b"is_active".to_string(),
        ];

        let values = vector[
            b"{name}".to_string(),
            b"{description}".to_string(),
            b"{image_url}".to_string(),
            b"{link}".to_string(),
            b"{is_active}".to_string(),
        ];

        let mut display = display::new_with_fields<Component>(
            &publisher, keys, values, ctx
        );

        display::update_version(&mut display);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
        transfer::share_object(
            DBioApp {
                id: object::new(ctx),
                total_user: 0
            }
        );


    }

    public fun mint(
        _name: String,
        _description: String,
        _image_url: String,
        _link: String,
        ctx: &mut TxContext
    ): Component {
        Component {
            id: object::new(ctx),
            name: _name,
            description: _description,
            image_url: _image_url,
            link: _link,
            is_active: true
        }
    }


    public entry fun mint_and_take(
        _name: String,
        _description: String,
        _image_url: String,
        _link: String,
        _dbio_app: &mut DBioApp,
        ctx: &mut TxContext
    ) {
            let sender = tx_context::sender(ctx);
            let is_existed = existed(_dbio_app, ctx);
            assert!(is_existed, EUserNotExist);
            let component = mint(_name, _description, _image_url, _link, ctx);
            let mut user = dof::borrow_mut<address, User>(&mut _dbio_app.id, sender);
            vector::insert<ID>(&mut user.components, object::uid_to_inner(&component.id), 0);
            transfer::public_transfer(component, sender);
    }

    public entry fun existed(
        _dbio_app: &mut DBioApp,
        ctx: &mut TxContext
    ): bool {
        let sender = tx_context::sender(ctx);
        dof::exists_<address>(&mut _dbio_app.id, sender)
    }

    public entry fun new_user(
        _dbio_app: &mut DBioApp,
        ctx: &mut TxContext
    ) {
        let is_existed = existed(_dbio_app, ctx);
        assert!(!is_existed, EUserExist);
        let new_user = User {
            id: object::new(ctx),
            components: vector::empty(),
            total_component: 0
        };
        dof::add(&mut _dbio_app.id, tx_context::sender(ctx), new_user);
    }

    public entry fun get_components(
        _dbio_app: &mut DBioApp,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let is_existed = existed(_dbio_app, ctx);
        if(!is_existed) {
            new_user(_dbio_app, ctx);
            return;
        };
        let user = dof::borrow<address, User>(&mut _dbio_app.id, sender);
        event::emit(GetDataEvent {
            id: object::uid_to_inner(&user.id),
            components: user.components
        });
    }

    public entry fun get_user_components(
        u_address: address,
        _dbio_app: &mut DBioApp,
        ctx: &mut TxContext
    ) {
        let user = dof::borrow<address, User>(&mut _dbio_app.id, u_address);
        event::emit(GetDataEvent {
            id: object::uid_to_inner(&user.id),
            components: user.components
        });
    }

    public entry fun remove(
        component: &mut Component,
        ctx: &mut TxContext
    ) {
        component.is_active = false;
    }
}

//create display
//remove object
