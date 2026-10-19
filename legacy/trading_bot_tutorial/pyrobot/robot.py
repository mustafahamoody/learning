# Data management
import pandas as pd

# Communication with api
from td.client import TDClient #TDOD Replace with IBKR
from td.utils import ms_since_epoch

from datetime import datatime, time, timezone

# Importing Data typing
from typing import List, Dict, Union


class PyRobot():
    def __init__(self, client_id: str, redirect_uri: str, credentials_path: str = None, trading_account: str = None) -> None:

        self.trading_account: str = trading_account
        self.client_id: str = client_id
        self.redirect_uri: str = redirect_uri
        self.credentials_path: str = credentials_path
        self.session: TDClient = self._create_session()
        self.trades: dict = {}
        self.historical_prices: dict = {}
        self.stock_frame = None

    def _create_session(self) -> TDClient:
        
        # Initialize Client Session
        td_client = TDClient(
            client_id = self.client_id,
            redirect_uri = self.redirect_uri,
            credentials_path = self.credentials_path
        )

        # Log into session
        td_client.login()

        return td_client
    
    @property
    def pre_market_open(self) -> bool:
        # Check if pre-market is open
        pre_market_start_time = datatime.now().replace(hours=12, minute=00, second=00, tzinfo=timezone.utc).timestamp()
        market_start_time = datatime.now().replace(hours=13, minute=30, second=00, tzinfo=timezone.utc).timestamp()
        right_now = datatime.now().replace(tzinfo=timezone.utc).timestamp()

        return True if market_start_time >= right_now >= pre_market_start_time else False

    @property
    def post_market_open(self) -> bool:
        # Check if post-market is open
        post_market_end_time = datatime.now().replace(hours=22, minute=30, second=00, tzinfo=timezone.utc).timestamp()
        market_end_time = datatime.now().replace(hours=20, minute=00, second=00, tzinfo=timezone.utc).timestamp()
        right_now = datatime.now().replace(tzinfo=timezone.utc).timestamp()

        return True if post_market_end_time >= right_now >= market_end_time else False


    @property
    def regular_market_open(self) -> bool:
        # Check if market is open
        market_start_time = datatime.now().replace(hours=13, minute=30, second=00, tzinfo=timezone.utc).timestamp()
        market_end_time = datatime.now().replace(hours=20, minute=00, second=00, tzinfo=timezone.utc).timestamp()
        right_now = datatime.now().replace(tzinfo=timezone.utc).timestamp()

        return True if market_start_time >= right_now >= market_end_time else False


    def create_portfolio(self):
        pass

    def create_trade(self):
        pass

    def grab_current_quore(self) -> dict:
        pass
    
    def get_historical_prices(self) -> List[Dict]:
        pass

    def create_stock_frame(self):
        pass
