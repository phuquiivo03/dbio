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
    
    public struct GetDataEvent has copy, drop {
        id: ID,
        components: vector<ID>,
    }

    public struct Component has key, store {
        id: UID,
        name: String,
        description: String,
        image_url: String,
        link: String
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

    fun init(otw: DBIO, ctx: &mut TxContext) {
        let publisher = package::claim(otw, ctx);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
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
            link: _link
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
            let component = mint(_name, _description, _image_url, _link, &mut ctx);
            let mut user = dof::borrow_mut<address, User>(&mut _dbio_app.id, sender);
            user.components.add
            //continue
    }

    public entry fun existed(
        _dbio_app: &mut DBioApp,
        ctx: &mut TxContext
        ): bool {
        let sedner = tx_context::sedner(ctx);
        dof::exists_<address>(&mut _dbio_app.id, sender)
    }

    public entry fun new_user(ctx: &mut TxContext) {

    }

    public entry fun get_components(
        _dbio_app: &mut DBioApp,
        ctx: &mut TxContext
        ) {
        let sender = tx_context::sender(ctx);
        let is_existed = existed(_dbio_app);
        assert!(is_existed, EUserNotExist);
        let user = dof::borrow<address, User>(&mut _dbio_app.id, sender);
        event::emit(GetDataEvent {
            id: object::uid_to_inner(&user.id),
            components: &user.components
        });
    }
}